# Classification only. Pair with Foreman Boolean puppet_managed=false.
class role::unmanaged {
  include profile::management
  if $profile::management::managed {
    fail('role::unmanaged requires Foreman Boolean puppet_managed=false')
  }
}
