# GPU server role; common settings are included without assigning role::base too.
class role::gpu_svr {
  include profile::management
  if $profile::management::managed {
    include profile::base
    include profile::gpu_system
  }
}
