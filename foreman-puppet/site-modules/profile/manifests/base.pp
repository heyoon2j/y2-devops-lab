# Fail catalog compilation before applying settings to unsupported nodes.
class profile::base {
  # Foreman Host Group parameter, not a node-supplied CSP fact.
  $csp_value = getvar('::csp')
  if $csp_value !~ Enum['aws', 'gcp', 'kc'] {
    fail('csp ENC parameter must be aws, gcp or kc; set it on the Foreman Host Group')
  }

  if $facts['deploy_env'] !~ Enum['dev', 'prd'] {
    fail('deploy_env must be dev or prd; create the external fact before the first Puppet run')
  }

  $expected_deploy_env = $environment ? {
    'development' => 'dev',
    'production'  => 'prd',
    default       => fail('profile::base supports Puppet environments development or production only'),
  }
  if $facts['deploy_env'] != $expected_deploy_env {
    fail('deploy_env does not match the Puppet code environment assigned to this node')
  }

  case $facts['os']['name'] {
    'Ubuntu': {
      if $facts['os']['release']['full'] !~ /^(20|24|26)[.]04([.]|$)/ {
        fail('profile::base supports Ubuntu 20.04, 24.04 or 26.04 only')
      }
      if $facts['os']['architecture'] !~ Enum['amd64', 'arm64'] {
        fail('profile::base supports Ubuntu os.architecture amd64 or arm64 only')
      }
    }
    'Rocky': {
      if $facts['os']['release']['full'] !~ /^(8|9)([.]|$)/ {
        fail('profile::base supports Rocky 8 or 9 only')
      }
      if $facts['os']['architecture'] !~ Enum['x86_64', 'aarch64'] {
        fail('profile::base supports Rocky os.architecture x86_64 or aarch64 only')
      }
    }
    default: {
      fail('profile::base supports Ubuntu or Rocky only')
    }
  }

  include profile::packages
  include profile::example_file
}
