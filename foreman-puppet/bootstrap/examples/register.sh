#!/usr/bin/env bash
# Copy these assignments into existing user-data and replace the example values.
# Source the function from the reviewed artifact already placed on the node.
set +x
set +a
source /opt/foreman-puppet/bootstrap/user-data/register.sh

FOREMAN_URL="https://foreman.dev.example.internal"
FOREMAN_CA_CERT="/etc/company-pki/ca.pem"
FOREMAN_USERNAME="bootstrap_dev"
# Do not export the PAT or put its literal value into user-data.
FOREMAN_PAT=$(aws ssm get-parameter --name /foreman/dev/bootstrap-pat \
  --region ap-northeast-2 --with-decryption --output json |
  jq -er '.Parameter | select(.Type=="SecureString") | .Value') || exit 1

NODE_NAME="i-123.dev.example.internal" # Must match the agent certname.
ORGANIZATION_ID=1
LOCATION_ID=1
HOSTGROUP_ID=1                       # CSP host group: aws/gcp/kc.
ENVIRONMENT_ID=1                     # development for dev; production for prd.
ROLE_ID=1                            # The desired role::... Puppet Class ID.
PUPPET_PROXY_ID=1
PUPPET_CA_PROXY_ID=1
DEPLOY_ENV="dev"
TEAM=""                              # Empty means no host-level override.
DR_SITE="primary"                    # primary/secondary or empty.
PUPPET_MANAGED=true                   # role::unmanaged must use false.

# Build API JSON here; the registration function only sends PAYLOAD.
PAYLOAD=$(jq -n \
  --arg name "$NODE_NAME" --arg env "$DEPLOY_ENV" --arg team "$TEAM" --arg dr "$DR_SITE" \
  --argjson org "$ORGANIZATION_ID" --argjson location "$LOCATION_ID" --argjson group "$HOSTGROUP_ID" \
  --argjson environment "$ENVIRONMENT_ID" --argjson role "$ROLE_ID" \
  --argjson proxy "$PUPPET_PROXY_ID" --argjson ca "$PUPPET_CA_PROXY_ID" --argjson managed "$PUPPET_MANAGED" \
  '{host:{name:$name,managed:false,build:false,overwrite:false,
    organization_id:$org,location_id:$location,hostgroup_id:$group,
    puppet_proxy_id:$proxy,puppet_ca_proxy_id:$ca,
    puppet_attributes:{environment_id:$environment,puppetclass_ids:[$role]},
    host_parameters_attributes:([
      {name:"deploy_env",value:$env,parameter_type:"string"},
      {name:"puppet_managed",value:($managed|tostring),parameter_type:"boolean"}
    ] + (if $team=="" then [] else [{name:"team",value:$team,parameter_type:"string"}] end)
      + (if $dr=="" then [] else [{name:"dr_site",value:$dr,parameter_type:"string"}] end))}}') || exit 1

foreman_register || exit 1
unset FOREMAN_PAT
