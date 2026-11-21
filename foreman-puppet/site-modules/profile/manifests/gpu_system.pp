# Extension point for GPU-specific OS policy.
# Add resources after driver, kernel and MIG management policies are defined.
# GPU presence and MIG configuration remain observed facts, not automatic actions.
class profile::gpu_system (
  Boolean $manage = true,
) {
  include profile::management
  # Future resources must be guarded by this value; no GPU policy exists yet.
  $enabled = $profile::management::managed and $manage
}
