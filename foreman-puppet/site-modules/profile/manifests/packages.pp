# Values are supplied by environment Hiera through automatic parameter lookup.
class profile::packages (
  Array[String[1]] $packages,
) {
  package { $packages:
    ensure => installed,
  }
}
