#!/usr/bin/env bash
# Apply Foreman + OpenVox answers together; sources remain separate YAML files.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec python3 "$script_dir/../lib/bootstrap.py" openvox-config "$@"
