# Bash function. Args: URL CA USER PAT NAME ORG LOCATION GROUP ENV ROLE PROXY CA_PROXY DEPLOY_ENV MANAGED [TEAM] [DR_SITE]
foreman_register() (
  set +x
  set +a
  export -n FOREMAN_PAT
  [[ $# -ge 14 && $# -le 16 ]] || return 1
  local +x auth status
  auth="$3:$4"
  [[ "$auth" =~ ^[!-~]+$ ]] || return 1
  auth=${auth//\\/\\\\}
  auth=${auth//\"/\\\"}
  local payload
  payload=$(jq -n \
    --arg name "$5" --arg env "${13}" --arg team "${15:-}" --arg dr "${16:-}" \
    --argjson org "$6" --argjson location "$7" --argjson group "$8" \
    --argjson environment "$9" --argjson role "${10}" \
    --argjson proxy "${11}" --argjson ca "${12}" --argjson managed "${14}" \
    '{host:{name:$name,managed:false,build:false,overwrite:false,
      organization_id:$org,location_id:$location,hostgroup_id:$group,
      puppet_proxy_id:$proxy,puppet_ca_proxy_id:$ca,
      puppet_attributes:{environment_id:$environment,puppetclass_ids:[$role]},
      host_parameters_attributes:([
        {name:"deploy_env",value:$env,parameter_type:"string"},
        {name:"puppet_managed",value:($managed|tostring),parameter_type:"boolean"}
      ] + (if $team=="" then [] else [{name:"team",value:$team,parameter_type:"string"}] end)
        + (if $dr=="" then [] else [{name:"dr_site",value:$dr,parameter_type:"string"}] end))}}') || return 1
  status=$(printf 'user = "%s"\n' "$auth" |
    curl -q --silent --config - --noproxy '*' --proto '=https' \
      --cacert "$2" --connect-timeout 10 --max-time 60 --retry 0 \
      --header 'Content-Type: application/json' --data-binary "$payload" \
      --output /dev/null --write-out '%{http_code}' \
      "${1%/}/api/hosts") || return 1
  [[ "$status" == 2?? ]]
)
