# Fail catalog compilation before applying settings to unsupported nodes.
class profile::base {
  if $facts['deploy_env'] !~ Enum['dev', 'prd'] {
    fail('deploy_env must be dev or prd; create the external fact before the first Puppet run')
  }

  if $facts['os']['name'] != 'Ubuntu' or $facts['os']['release']['full'] !~ /^24[.]04([.]|$)/ {
    fail('role::base supports Ubuntu 24.04 only')
  }

  if $facts['os']['architecture'] !~ Enum['amd64', 'arm64'] {
    fail('role::base supports os.architecture amd64 or arm64 only')
  }

  include profile::packages
  include profile::node_info
}
