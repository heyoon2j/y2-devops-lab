# Assign this role to ordinary hosts through Foreman, independently of CSP.
class role::base {
  include profile::management
  if $profile::management::managed {
    include profile::base
  }
}
