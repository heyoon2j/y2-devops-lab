# Values are supplied by environment Hiera through automatic parameter lookup.
class profile::packages (
  Boolean $manage = true,
  Array[String[1]] $packages = [],
) {
  include profile::management
  if $profile::management::managed and $manage {
    package { $packages:
      ensure => installed,
    }
  }
}
