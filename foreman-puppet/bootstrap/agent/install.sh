#!/usr/bin/env bash
# agent: install. Defaults to plan-only; pass --apply explicitly on the target.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$script_dir/../lib/bootstrap.sh" agent-install "$@"
