# Fail catalog compilation before applying settings to unsupported nodes.
class profile::base {
  if $facts['deploy_env'] !~ Enum['dev', 'prd'] {
    fail('deploy_env must be dev or prd; create the external fact before the first Puppet run')
  }

  $expected_deploy_env = $environment ? {
    'development' => 'dev',
    'production'  => 'prd',
    default       => fail('role::base supports Puppet environments development or production only'),
  }
  if $facts['deploy_env'] != $expected_deploy_env {
    fail('deploy_env does not match the Puppet code environment assigned to this node')
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
