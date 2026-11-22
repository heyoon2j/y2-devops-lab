#!/usr/bin/env bash
# Direct Bash/curl Foreman API client; no Ruby or agent installation required.
set -euo pipefail
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf '%s\n' 'Usage: register.sh --config FILE [--apply]' 'Default: offline plan. --apply: root-only, create-only Foreman API registration.'
  exit 0
fi
mode=plan
if [[ $# == 3 && "$3" == --apply ]]; then mode=apply; set -- "$1" "$2"; fi
if [[ $# != 2 || "$1" != --config ]]; then
  printf '%s\n' 'Usage: register.sh --config FILE [--apply]' >&2
  exit 2
fi
if [[ "$mode" == apply && $EUID != 0 ]]; then
  printf '%s\n' '--apply requires root' >&2
  exit 1
fi
artifact_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$artifact_root/bootstrap/user-data/register.bash"
config_path=$2
[[ "$config_path" = /* ]] || config_path="$PWD/$config_path"
foreman_register "$artifact_root" "$config_path" "$mode"
