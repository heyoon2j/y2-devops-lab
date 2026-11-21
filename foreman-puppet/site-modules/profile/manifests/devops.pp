# Team-specific system settings extension point; no additional resources yet.
class profile::devops (
  Boolean $manage = true,
) {
  include profile::management
  # Future resources must be guarded by $enabled.
  $enabled = $profile::management::managed and $manage
}
