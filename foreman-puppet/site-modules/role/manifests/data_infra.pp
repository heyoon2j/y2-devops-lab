# Assign one role per host in Foreman. Team facts do not select this class.
class role::data_infra {
  include profile::management
  if $profile::management::managed {
    include profile::base
    include profile::data_infra
  }
}
