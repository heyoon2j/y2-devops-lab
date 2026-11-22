# Source this file from an existing Bash user-data script; sourcing does not register.
# Keep xtrace disabled around bootstrap/credential operations.
# Usage: foreman_register ROOT CONFIG [plan|apply]
foreman_register() (
  set +x
  set -euo pipefail
  if (( $# < 2 || $# > 3 )); then
    printf '%s\n' 'Usage: foreman_register ROOT CONFIG [plan|apply]' >&2
    return 2
  fi
  local artifact_root=$1 registration_config=$2 mode=${3:-plan}
  [[ "$artifact_root" = /* && "$registration_config" = /* ]] || {
    printf '%s\n' 'Artifact root and registration config must be absolute paths.' >&2
    return 2
  }
  [[ -f "$artifact_root/bootstrap/agent/register.sh" && -f "$registration_config" ]] || {
    printf '%s\n' 'Prepare the bootstrap artifact and registration config first.' >&2
    return 2
  }
  case "$mode" in
    plan) bash "$artifact_root/bootstrap/agent/register.sh" --config "$registration_config" ;;
    apply) bash "$artifact_root/bootstrap/agent/register.sh" --config "$registration_config" --apply ;;
    *) printf '%s\n' 'Mode must be plan or apply.' >&2; return 2 ;;
  esac
)
