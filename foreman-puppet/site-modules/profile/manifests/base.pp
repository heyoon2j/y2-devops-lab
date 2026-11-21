# Fail catalog compilation before applying settings to unsupported nodes.
class profile::base (
  Boolean $manage = true,
) {
  include profile::management
  if $profile::management::managed and $manage {
    # Foreman Host Group parameter, not a node-supplied CSP fact.
    $csp_value = getvar('::csp')
    if $csp_value !~ Enum['aws', 'gcp', 'kc'] {
      fail('csp ENC parameter must be aws, gcp or kc; set it on the Foreman Host Group')
    }

    # Central Foreman parameters; node-supplied Facts never select these values.
    $deploy_env_value = getvar('::deploy_env')
    $team_value = getvar('::team')
    $dr_site_value = getvar('::dr_site')
    if $deploy_env_value !~ Enum['dev', 'prd'] {
      fail('deploy_env ENC parameter must be dev or prd; set it on the Foreman host')
    }
    if $team_value != undef and ($team_value == 'null' or $team_value !~ Pattern[/^[a-z][a-z0-9_-]*$/]) {
      fail('team ENC parameter must be a team name or unset')
    }
    if $dr_site_value != undef and $dr_site_value !~ Enum['primary', 'secondary'] {
      fail('dr_site ENC parameter must be primary, secondary or unset')
    }

    $expected_deploy_env = $environment ? {
      'development' => 'dev',
      'production'  => 'prd',
      default       => fail('profile::base supports Puppet environments development or production only'),
    }
    if $deploy_env_value != $expected_deploy_env {
      fail('deploy_env does not match the Puppet code environment assigned to this node')
    }

    case $facts['os']['name'] {
      'Ubuntu': {
        if $facts['os']['release']['full'] !~ /^(20|22|24|26)[.]04([.]|$)/ {
          fail('profile::base supports Ubuntu 20.04, 22.04, 24.04 or 26.04 only')
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
      'Amazon': {
        if $facts['os']['release']['full'] !~ /^(2|2023)([.]|$)/ {
          fail('profile::base supports Amazon Linux 2 or 2023 only')
        }
        if $facts['os']['architecture'] !~ Enum['x86_64', 'aarch64'] {
          fail('profile::base supports Amazon os.architecture x86_64 or aarch64 only')
        }
      }
      default: {
        fail('profile::base supports Ubuntu, Rocky or Amazon only')
      }
    }

    include profile::packages
    include profile::example_file
    include profile::services
    include profile::ssh
  }
}
