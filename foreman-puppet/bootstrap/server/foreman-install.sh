#!/usr/bin/env bash
# server: foreman-install. Defaults to plan-only; pass --apply explicitly on the target.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec python3 "$script_dir/../lib/bootstrap.py" foreman-install "$@"
