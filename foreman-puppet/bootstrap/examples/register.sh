#!/usr/bin/env bash
# Copy these assignments into existing user-data and replace the example values.
# Source the function from the reviewed artifact already placed on the node.
set +x
set +a
source /opt/foreman-puppet/bootstrap/user-data/register.sh

FOREMAN_URL="https://foreman.dev.example.internal"
FOREMAN_CA_CERT="/etc/company-pki/ca.pem" # Trust the ACM listener issuer, not necessarily the backend CA.
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

# The function builds PAYLOAD internally. Argument order follows the groups below:
# connection / node+organization+location / hostgroup+environment+role / proxies / parameters
foreman_register \
  "$FOREMAN_URL" "$FOREMAN_CA_CERT" "$FOREMAN_USERNAME" "$FOREMAN_PAT" \
  "$NODE_NAME" "$ORGANIZATION_ID" "$LOCATION_ID" \
  "$HOSTGROUP_ID" "$ENVIRONMENT_ID" "$ROLE_ID" \
  "$PUPPET_PROXY_ID" "$PUPPET_CA_PROXY_ID" \
  "$DEPLOY_ENV" "$PUPPET_MANAGED" "$TEAM" "$DR_SITE" || exit 1
unset FOREMAN_PAT
