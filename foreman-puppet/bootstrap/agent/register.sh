#!/usr/bin/env bash
# Requires the installed OpenVox agent Ruby; default is an offline plan.
set -euo pipefail
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf '%s\n' 'Usage: register.sh --config FILE [--apply]' 'Default: offline plan. --apply: root-only, create-only Foreman registration.'
  exit 0
fi
if [[ "${1:-}" == --help && $# == 1 ]]; then
  printf '%s\n' 'Usage: register.sh --config FILE [--apply]' 'Default: offline plan. --apply: root, HTTPS create-only registration.'
  exit 0
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ruby_bin=${FOREMAN_BOOTSTRAP_RUBY:-/opt/puppetlabs/puppet/bin/ruby}
if [[ ! -x "$ruby_bin" ]]; then
  printf '%s\n' 'Install OpenVox agent first, or set FOREMAN_BOOTSTRAP_RUBY to a Ruby executable.' >&2
  exit 1
fi
exec "$ruby_bin" "$script_dir/../lib/register.rb" "$@"
