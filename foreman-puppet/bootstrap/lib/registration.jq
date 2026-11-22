# Validation and payload helpers for the Bash API client. No secrets enter jq argv.
def string_matching($re): type == "string" and test($re);
def positive_id: type == "number" and . > 0 and floor == .;
def valid_team: . == null or string_matching("^[a-z][a-z0-9_-]{0,63}$");
def valid_dr: . == null or . == "primary" or . == "secondary";
def valid_role: IN("role::base", "role::unmanaged", "role::devops", "role::data_infra");
def env_for: if . == "dev" then "development" elif . == "prd" then "production" else null end;
def valid_config:
  . as $c | .foreman as $f | .host as $h | .auth as $a |
  ($c | type == "object" and (keys - ["foreman","host","auth"] | length == 0)) and
  ($f | type == "object" and (keys - ["url","ca_cert","username"] | length == 0)) and
  ($h | type == "object" and (keys - ["name","bootstrap_identity","csp","organization_id","location_id","hostgroup_id","environment_id","role_id","puppet_proxy_id","puppet_ca_proxy_id","environment","role","parameters"] | length == 0)) and
  ($a | type == "object" and (keys - ["source","region","reference","path"] | length == 0)) and
  ($f.url | string_matching("^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$")) and
  ($f.ca_cert | string_matching("^/")) and
  ($f.username | string_matching("^[a-zA-Z0-9_.@-]+$")) and
  ([$h.organization_id,$h.location_id,$h.hostgroup_id,$h.environment_id,$h.role_id,$h.puppet_proxy_id,$h.puppet_ca_proxy_id] | all(positive_id)) and
  ($h.name | string_matching("^[a-z0-9][a-z0-9.-]*\\.[a-z0-9-]+$") and length <= 253) and
  ($h.csp | IN("aws","gcp","kc")) and ($h.role | valid_role) and
  ($h.parameters.deploy_env | IN("dev","prd")) and
  ($h.environment == ($h.parameters.deploy_env | env_for)) and
  ($h.parameters | type == "object" and (keys - ["deploy_env","team","dr_site","puppet_managed"] | length == 0)) and
  ($h.parameters.team | valid_team) and ($h.parameters.dr_site | valid_dr) and
  ($h.parameters.puppet_managed | type == "boolean") and
  ($h.role != "role::unmanaged" or $h.parameters.puppet_managed == false) and
  ($h.bootstrap_identity | string_matching("^[a-zA-Z0-9_:/\\.=-]{3,256}$") and startswith($h.csp + "/")) and
  (if $a.source == "aws_ssm" then
    ($a.region | string_matching("^[a-z0-9-]+$")) and ($a.reference | string_matching("^[a-zA-Z0-9_/\\.:-]+$"))
   elif $a.source == "file" then ($a.path | string_matching("^/")) else false end);
def valid_policy($h):
  . as $enc | .parameters as $p |
  (.classes | type == "object") and
  ([.classes | keys[] | select(startswith("role::"))] as $roles |
    ($roles | length == 1) and ($roles[0] | valid_role) and
    ($p.puppet_managed | type == "boolean") and
    ($roles[0] != "role::unmanaged" or $p.puppet_managed == false)) and
  ($p.bootstrap_identity == $h.bootstrap_identity) and ($p.csp == $h.csp) and
  ($p.deploy_env | IN("dev","prd")) and ($enc.environment == ($p.deploy_env | env_for)) and
  ($p.team | valid_team) and ($p.dr_site | valid_dr);
def create_payload:
  .host as $h |
  {host: (($h | {name,organization_id,location_id,hostgroup_id,puppet_proxy_id,puppet_ca_proxy_id}) +
    {managed:false,build:false,overwrite:false,
     puppet_attributes:{environment_id:$h.environment_id,puppetclass_ids:[$h.role_id]},
     host_parameters_attributes:($h.parameters + {bootstrap_identity:$h.bootstrap_identity} | to_entries |
       map(select(.value != null) | {name:.key,value:(.value|tostring),parameter_type:(if (.value|type)=="boolean" then "boolean" else "string" end)}))})};

def trim_pat: sub("^[ \\t\\r\\n\\f\\u000b]+";"") | sub("[ \\t\\r\\n\\f\\u000b]+$";"");
def valid_pat: string_matching("^[!-~]{16,2048}$");
