# Hiera supplies per-unit policies. Empty by default: no services are managed.
class profile::services (
  Boolean $manage = true,
  Hash[String[1], Hash[String[1], Any]] $units = {},
) {
  include profile::management
  if $profile::management::managed and $manage {
    $units.each |String $unit, Hash $policy| {
      profile::service_control { $unit:
        * => $policy,
      }
    }
  }
}
