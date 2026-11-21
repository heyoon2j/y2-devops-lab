# Reusable systemd policy; no resources exist until a caller declares an instance.
# Pass managed File paths via config_files. Do not notify this defined resource:
# subscribe is wired only to the refresh Exec, not to the state enforcement Exec.
define profile::service_control (
  Boolean $manage = true,
  Enum['preserve', 'running', 'stopped'] $state_policy = 'preserve',
  Enum['none', 'reload', 'restart'] $change_action = 'none',
  Array[String[1]] $config_files = [],
  Integer[1, 3600] $timeout = 60,
  Pattern[/\A\/[a-zA-Z0-9_\/.\-]+\z/] $systemctl = '/usr/bin/systemctl',
) {
  include profile::management
  if $profile::management::managed and $manage {
    if $title !~ Pattern[/\A[a-zA-Z0-9][a-zA-Z0-9_.@:\-]*\z/] {
      fail('service_control title must be a valid systemd unit name')
    }
    if $state_policy == 'stopped' and $change_action != 'none' {
      fail('stopped state_policy requires change_action none')
    }
    if $change_action != 'none' and $config_files.empty {
      fail('config_files is required for reload or restart change_action')
    }

    $active_command = [$systemctl, 'is-active', '--quiet', '--', $title]
    $refresh_title = "profile-service-${title}-refresh"
    $state_title = "profile-service-${title}-state"

    if $change_action != 'none' {
      exec { $refresh_title:
        command     => [$systemctl, $change_action, '--', $title],
        refreshonly => true,
        onlyif      => [$active_command],
        subscribe   => File[$config_files],
        timeout     => $timeout,
        tries       => 1,
        logoutput   => on_failure,
      }
    }

    case $state_policy {
      'running': {
        exec { $state_title:
          command   => [$systemctl, 'start', '--', $title],
          unless    => [$active_command],
          require   => File[$config_files],
          timeout   => $timeout,
          tries     => 1,
          logoutput => on_failure,
        }
        # Refresh an already-running service first; otherwise start it once
        # with the new config, without a redundant reload/restart afterwards.
        if $change_action != 'none' {
          Exec[$refresh_title] -> Exec[$state_title]
        }
      }
      'stopped': {
        # Include transient startup/reload states, not just fully active units.
        $stop_guard = "${systemctl} show --property=ActiveState --value -- ${title} | /bin/grep -Eq '^(active|activating|reloading)$'"
        exec { $state_title:
          command   => [$systemctl, 'stop', '--', $title],
          onlyif    => [['/bin/sh', '-c', $stop_guard]],
          require   => File[$config_files],
          timeout   => $timeout,
          tries     => 1,
          logoutput => on_failure,
        }
      }
      default: {
        # preserve does not enforce a process state or a boot enable flag.
      }
    }
  }
}
