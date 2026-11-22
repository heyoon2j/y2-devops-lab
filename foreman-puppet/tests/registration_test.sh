#!/usr/bin/env bash
# Development test runner: Go standard library + Bash/curl/jq, no Ruby.
set -euo pipefail
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_root/bootstrap/user-data/go"
exec "${FOREMAN_BOOTSTRAP_GO:-go}" test -count=1 ./...
