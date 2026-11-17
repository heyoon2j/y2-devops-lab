# Opt-in SSH drop-in; image/bootstrap must install OpenSSH and its Include.
class profile::ssh (
  Boolean $manage = false,
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $banner = '/etc/issue.net',
  Boolean $password_authentication = true,
  Enum['yes', 'no', 'prohibit-password', 'forced-commands-only'] $permit_root_login = 'yes',
  Enum['preserve', 'running', 'stopped'] $state_policy = 'preserve',
  Enum['none', 'reload', 'restart'] $change_action = 'reload',
  Integer[1, 3600] $timeout = 60,
  Integer[1, 300] $validation_timeout = 15,
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $config_path = '/etc/ssh/sshd_config.d/00-foreman-puppet.conf',
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $main_config = '/etc/ssh/sshd_config',
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $sshd = '/usr/sbin/sshd',
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $ruby = '/opt/puppetlabs/puppet/bin/ruby',
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $validator_dir = '/etc/puppetlabs/puppet/ssh-validation',
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $timeout_command = '/usr/bin/timeout',
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $systemctl = '/usr/bin/systemctl',
) {
  include profile::management
  if $profile::management::managed and $manage {
    if $config_path == $main_config {
      fail('profile::ssh config_path must differ from main_config; only the drop-in is managed')
    }
    $unit = $facts['os']['name'] ? {
      'Ubuntu' => 'ssh.service',
      'Rocky'  => 'sshd.service',
      'Amazon' => 'sshd.service',
      default  => fail('profile::ssh supports Ubuntu, Rocky or Amazon only'),
    }
    # The parent of validator_dir must exist; no recursive ownership of /usr/local.
    file { $validator_dir:
      ensure => directory,
      owner => 'root', group => 'root', mode => '0755',
    }
    $validator = "${validator_dir}/validate-sshd-config.rb"
    file { $validator:
      ensure => file,
      owner => 'root', group => 'root', mode => '0644',
      content => file('profile/validate-sshd-config.rb'),
      require => File[$validator_dir],
    }
    # Existing sshd_config and drop-in directory are bootstrap prerequisites.
    file { $config_path:
      ensure => file,
      owner => 'root', group => 'root', mode => '0600',
      content => epp('profile/sshd.conf.epp', {
        'banner' => $banner,
        'password_authentication' => $password_authentication,
        'permit_root_login' => $permit_root_login,
      }),
      backup => false,
      show_diff => false,
      validate_cmd => "${timeout_command} --signal=TERM --kill-after=5s ${validation_timeout}s ${ruby} ${validator} % ${config_path} ${main_config} ${sshd}",
      require => File[$validator],
    }
    profile::service_control { $unit:
      state_policy => $state_policy,
      change_action => $change_action,
      config_files => [$config_path],
      timeout => $timeout,
      systemctl => $systemctl,
    }
  }
}
