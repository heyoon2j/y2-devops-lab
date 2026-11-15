# Assign one role per host in Foreman. Team facts do not select this class.
class role::devops {
  include profile::management
  if $profile::management::managed {
    include profile::base
    include profile::devops
  }
}
