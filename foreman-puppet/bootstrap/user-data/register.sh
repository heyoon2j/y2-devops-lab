# Source from Bash user-data. Caller prepares connection variables and PAYLOAD.
foreman_register() (
  set +x
  set +a
  export -n FOREMAN_PAT
  local +x auth status
  auth="${FOREMAN_USERNAME}:${FOREMAN_PAT}"
  [[ "$auth" =~ ^[!-~]+$ ]] || return 1
  auth=${auth//\\/\\\\}
  auth=${auth//\"/\\\"}
  status=$(printf 'user = "%s"\n' "$auth" |
    curl -q --silent --config - --noproxy '*' --proto '=https' \
      --cacert "$FOREMAN_CA_CERT" --connect-timeout 10 --max-time 60 --retry 0 \
      --header 'Content-Type: application/json' --data-binary "$PAYLOAD" \
      --output /dev/null --write-out '%{http_code}' \
      "${FOREMAN_URL%/}/api/hosts") || return 1
  [[ "$status" == 2?? ]]
)
