# Source from an existing Bash user-data. Sourcing alone makes no API requests.
# Usage: foreman_register ARTIFACT_ROOT CONFIG [plan|apply]
# All helper functions and options live in a subshell, preserving the caller.
foreman_register() (
  set +x
  set +a
  set -euo pipefail
  export LC_ALL=C
  fail() { printf '%s\n' "$1" >&2; return 1; }
  if (( $# < 2 || $# > 3 )); then fail 'Usage: foreman_register ROOT CONFIG [plan|apply]'; return 2; fi
  local artifact_root=$1 config_path=$2 mode=${3:-plan}
  [[ "$artifact_root" = /* && "$config_path" = /* ]] || { fail 'Use absolute artifact/config paths'; return 2; }
  [[ "$mode" == plan || "$mode" == apply ]] || { fail 'Mode must be plan or apply'; return 2; }
  command -v jq >/dev/null || { fail 'jq is required'; return 1; }
  local jq_dir="$artifact_root/bootstrap/lib" cfg host
  cfg=$(jq -ce -L "$jq_dir" 'include "registration"; if valid_config then . else error("input") end' "$config_path" 2>/dev/null) || { fail 'Invalid registration input'; return 1; }
  host=$(jq -c '.host' <<<"$cfg")
  if [[ "$mode" == plan ]]; then
    jq '{mode:"plan",host:.host.name,policy:"create-only; existing central policy preserved",auth_source:.auth.source}' <<<"$cfg"
    return
  fi
  local prerequisite
  for prerequisite in curl timeout stat dd; do
    command -v "$prerequisite" >/dev/null || { fail 'curl, jq, timeout, stat and dd are required'; return 1; }
  done
  local +x pat escaped_pat secret_response
  local auth_source url username ca_cert
  auth_source=$(jq -r '.auth.source' <<<"$cfg")
  if [[ "$auth_source" == aws_ssm ]]; then
    secret_response=$(AWS_PAGER='' timeout --kill-after=5 30 aws ssm get-parameter \
      --name "$(jq -r '.auth.reference' <<<"$cfg")" --with-decryption \
      --region "$(jq -r '.auth.region' <<<"$cfg")" --output json 2>/dev/null) || { fail 'Could not securely load SSM PAT'; return 1; }
    pat=$(jq -er -L "$jq_dir" 'include "registration"; .Parameter | select(.Type == "SecureString") | .Value | select(type == "string") | trim_pat | select(valid_pat)' <<<"$secret_response" 2>/dev/null) || { fail 'SSM parameter must be SecureString'; return 1; }
    unset secret_response
  else
    local token_path before after
    token_path=$(jq -r '.auth.path' <<<"$cfg")
    [[ ! -L "$token_path" && -f "$token_path" ]] || { fail 'PAT file must be a regular file, not a symlink'; return 1; }
    before=$(stat -c '%u:%a:%s:%d:%i' -- "$token_path") || return 1
    [[ "$before" =~ ^0:600:([0-9]+): ]] && (( ${BASH_REMATCH[1]} <= 4096 )) || { fail 'PAT file must be root-owned, mode 0600, at most 4096 bytes'; return 1; }
    # GNU dd refuses symlinks and avoids blocking on a replaced FIFO.
    pat=$(dd if="$token_path" iflag=nofollow,nonblock bs=4097 count=1 status=none 2>/dev/null |
      jq -Rser -L "$jq_dir" 'include "registration"; trim_pat | select(valid_pat)' 2>/dev/null) || { fail 'Could not securely read PAT file'; return 1; }
    after=$(stat -c '%u:%a:%s:%d:%i' -- "$token_path") || return 1
    [[ ! -L "$token_path" && "$before" == "$after" ]] || { fail 'PAT file changed while reading'; return 1; }
  fi
  pat=${pat#"${pat%%[![:space:]]*}"}
  pat=${pat%"${pat##*[![:space:]]}"}
  [[ "$pat" =~ ^[!-~]{16,2048}$ ]] || { fail 'Invalid PAT format'; return 1; }
  url=$(jq -r '.foreman.url | rtrimstr("/")' <<<"$cfg")
  username=$(jq -r '.foreman.username' <<<"$cfg")
  ca_cert=$(jq -r '.foreman.ca_cert' <<<"$cfg")
  escaped_pat=${pat//\\/\\\\}
  escaped_pat=${escaped_pat//\"/\\\"}
  # No token in argv, temporary files, environment or logs. curl config is a pipe.
  api() {
    local method=$1 path=$2 response code
    local -a args=(-q --silent --noproxy '*' --proto '=https' --tlsv1.2 --cacert "$ca_cert"
      --connect-timeout 10 --max-time 60 --retry 0 --max-filesize 8388608
      --request "$method" --header 'Accept: application/json' --write-out $'\n%{http_code}' --config -)
    if (( $# == 3 )); then args+=(--header 'Content-Type: application/json' --data-binary "$3"); fi
    response=$(printf 'user = "%s:%s"\n' "$username" "$escaped_pat" |
      curl "${args[@]}" "$url$path" 2>/dev/null) || { fail 'Foreman transport failed (check TLS/network; POST is not retried)'; return 1; }
    code=${response##*$'\n'}
    [[ "$code" =~ ^2[0-9][0-9]$ ]] || { fail "Foreman HTTP $code"; return 1; }
    jq -ce '.' <<<"${response%$'\n'*}" 2>/dev/null || { fail 'Foreman returned invalid JSON'; return 1; }
  }
  lookup() {
    local query result
    query=$(jq -rn --arg name "$(jq -r '.name' <<<"$host")" '"name=\""+$name+"\""|@uri')
    result=$(api GET "/api/hosts?search=$query&per_page=100") || return 1
    jq -c --argjson h "$host" '
      if (.results|type)=="array" and (.subtotal|type)=="number" and .subtotal<=100 then
        [.results[]|select(.name==$h.name)] |
        if length<=1 then .[0] else error("ambiguous") end
      else error("incomplete") end' <<<"$result" 2>/dev/null || { fail 'Host lookup incomplete or ambiguous'; return 1; }
  }
  verify() {
    local found=$1 created=$2 id detail enc
    id=$(jq -er -L "$jq_dir" 'include "registration"; .id | select(positive_id)' <<<"$found" 2>/dev/null) || { fail 'Invalid host ID'; return 1; }
    detail=$(api GET "/api/hosts/$id") || return 1
    jq -e --argjson h "$host" --argjson id "$id" '.id==$id and .name==$h.name and .organization_id==$h.organization_id and .location_id==$h.location_id' <<<"$detail" >/dev/null || { fail 'Host name/organization/location mismatch'; return 1; }
    enc=$(api GET "/api/hosts/$id/enc") || return 1
    jq -e -L "$jq_dir" --argjson h "$host" 'include "registration"; .data | valid_policy($h)' <<<"$enc" >/dev/null 2>&1 || { fail 'Host identity or central policy mismatch; no overwrite performed'; return 1; }
    if [[ "$created" == true ]]; then
      jq -e --argjson h "$host" '.data as $e | $e.environment==$h.environment and
        ([$e.classes|keys[]|select(startswith("role::"))]==[$h.role]) and
        ($h.parameters|to_entries|all(. as $p | $e.parameters[$p.key]==$p.value))' <<<"$enc" >/dev/null || { fail 'Created host policy differs from input; check inheritance'; return 1; }
    fi
    local status=existing_preserved
    [[ "$created" == true ]] && status=created
    jq -n --arg status "$status" --argjson id "$id" --arg name "$(jq -r '.name' <<<"$host")" '{status:$status,id:$id,name:$name}'
  }
  local existing created endpoint id_key expected_key expected reference payload
  existing=$(lookup) || return 1
  if [[ "$existing" != null ]]; then verify "$existing" false; return; fi
  for endpoint in hostgroups environments puppetclasses; do
    case "$endpoint" in
      hostgroups) id_key=hostgroup_id; expected_key=csp ;;
      environments) id_key=environment_id; expected_key=environment ;;
      puppetclasses) id_key=role_id; expected_key=role ;;
    esac
    expected=$(jq -r --arg key "$expected_key" '.[$key]' <<<"$host")
    reference=$(api GET "/api/$endpoint/$(jq -r --arg key "$id_key" '.[$key]' <<<"$host")") || return 1
    jq -e --arg expected "$expected" '.name==$expected' <<<"$reference" >/dev/null || { fail 'Reference ID/name mismatch'; return 1; }
  done
  payload=$(jq -c -L "$jq_dir" 'include "registration"; create_payload' <<<"$cfg")
  if created=$(api POST /api/hosts "$payload"); then
    verify "$created" true
  else
    # POST may have succeeded before its response was lost. Reconcile, never POST again.
    existing=$(lookup) || return 1
    [[ "$existing" != null ]] || { fail 'Host creation failed; POST not retried'; return 1; }
    verify "$existing" false
  fi
)
