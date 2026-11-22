#!/usr/bin/env bash
# Explicit first-time internal CA initialization; never replaces an existing CA.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$script_dir/../lib/bootstrap.sh" ca-init "$@"
