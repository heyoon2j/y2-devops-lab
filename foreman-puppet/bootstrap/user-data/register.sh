# Bash function for existing user-data. Set the variables in examples/register.sh,
# then call foreman_register. Sourcing this file does not send a request.
foreman_register() (
  set +x
  set +a
  set -euo pipefail
  export LC_ALL=C
  # Keep the supplied PAT out of child-process environments, even if exported.
  export -n FOREMAN_PAT 2>/dev/null || true
  local key
  for key in FOREMAN_URL FOREMAN_CA_CERT FOREMAN_USERNAME FOREMAN_PAT NODE_NAME \
    ORGANIZATION_ID LOCATION_ID HOSTGROUP_ID ENVIRONMENT_ID ROLE_ID \
    PUPPET_PROXY_ID PUPPET_CA_PROXY_ID DEPLOY_ENV PUPPET_MANAGED; do
    [[ -n "${!key:-}" ]] || { printf 'Missing input: %s\n' "$key" >&2; return 1; }
  done
  [[ "$FOREMAN_URL" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$ &&
     "$FOREMAN_USERNAME" =~ ^[a-zA-Z0-9_.@-]+$ &&
     "$FOREMAN_PAT" =~ ^[!-~]{16,2048}$ &&
     "$NODE_NAME" =~ ^[a-z0-9][a-z0-9.-]*\.[a-z0-9-]+$ && ${#NODE_NAME} -le 253 ]] || {
    printf '%s\n' 'Invalid HTTPS origin, username, PAT or node FQDN' >&2; return 1;
  }
  for key in ORGANIZATION_ID LOCATION_ID HOSTGROUP_ID ENVIRONMENT_ID ROLE_ID PUPPET_PROXY_ID PUPPET_CA_PROXY_ID; do
    [[ "${!key}" =~ ^[1-9][0-9]*$ ]] || { printf 'Invalid ID: %s\n' "$key" >&2; return 1; }
  done
  [[ "$DEPLOY_ENV" == dev || "$DEPLOY_ENV" == prd ]] &&
  [[ "$PUPPET_MANAGED" == true || "$PUPPET_MANAGED" == false ]] &&
  [[ -z "${TEAM:-}" || "$TEAM" =~ ^[a-z][a-z0-9_-]{0,63}$ ]] &&
  [[ -z "${DR_SITE:-}" || "$DR_SITE" == primary || "$DR_SITE" == secondary ]] || {
    printf '%s\n' 'Invalid deploy_env, management flag, team or dr_site' >&2; return 1;
  }
  local payload status
  payload=$(jq -n \
    --arg name "$NODE_NAME" --arg deploy_env "$DEPLOY_ENV" --arg team "${TEAM:-}" --arg dr_site "${DR_SITE:-}" \
    --argjson org "$ORGANIZATION_ID" --argjson location "$LOCATION_ID" --argjson group "$HOSTGROUP_ID" \
    --argjson environment "$ENVIRONMENT_ID" --argjson role "$ROLE_ID" \
    --argjson proxy "$PUPPET_PROXY_ID" --argjson ca_proxy "$PUPPET_CA_PROXY_ID" --argjson managed "$PUPPET_MANAGED" \
    '{host:{name:$name,managed:false,build:false,overwrite:false,
      organization_id:$org,location_id:$location,hostgroup_id:$group,
      puppet_proxy_id:$proxy,puppet_ca_proxy_id:$ca_proxy,
      puppet_attributes:{environment_id:$environment,puppetclass_ids:[$role]},
      host_parameters_attributes:([
        {name:"deploy_env",value:$deploy_env,parameter_type:"string"},
        {name:"puppet_managed",value:($managed|tostring),parameter_type:"boolean"}
      ] + (if $team=="" then [] else [{name:"team",value:$team,parameter_type:"string"}] end)
        + (if $dr_site=="" then [] else [{name:"dr_site",value:$dr_site,parameter_type:"string"}] end))}}') || return 1
  # Send credentials through stdin, never curl argv or a temporary file.
  local +x escaped_pat
  escaped_pat=${FOREMAN_PAT//\\/\\\\}
  escaped_pat=${escaped_pat//\"/\\\"}
  status=$(printf 'user = "%s:%s"\n' "$FOREMAN_USERNAME" "$escaped_pat" |
    curl -q --silent --config - --noproxy '*' --proto '=https' --tlsv1.2 \
      --cacert "$FOREMAN_CA_CERT" --connect-timeout 10 --max-time 60 --retry 0 \
      --request POST --header 'Content-Type: application/json' --header 'Accept: application/json' \
      --data-binary "$payload" --output /dev/null --write-out '%{http_code}' \
      "${FOREMAN_URL%/}/api/hosts" 2>/dev/null) || {
    printf '%s\n' 'Foreman request failed; check TLS/network. No automatic retry.' >&2; return 1;
  }
  [[ "$status" =~ ^2[0-9][0-9]$ ]] || { printf 'Foreman HTTP %s; host was not overwritten\n' "$status" >&2; return 1; }
  printf 'Foreman host registered: %s\n' "$NODE_NAME"
)
