#!/usr/bin/env bash
# Read-only checks on the future development management VM. No sudo is required.
set -euo pipefail
export LC_ALL=C
usage() {
  cat <<'HELP'
Usage: bash scripts/server-preflight.sh HOST_FQDN FOREMAN_FQDN PUPPET_FQDN CA_FQDN
Checks the current machine against the Ubuntu 24.04 amd64 development baseline.
Reads OS/resources/DNS/listening ports only; does not install or change anything.
Exit 0: checks passed (review WARN/manual items); 1: failed check; 2: invalid input.
HELP
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if (( $# != 4 )); then usage >&2; exit 2; fi
for name in "$@"; do
  if (( ${#name} > 253 )) || [[ ! $name =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
    echo "Invalid lowercase FQDN: $name" >&2; exit 2
  fi
  case "$name" in
    *.example.internal|*.example.com|*.invalid) echo "Replace example FQDN: $name" >&2; exit 2 ;;
  esac
done
for cmd in awk df nproc uname hostname getent ip ss timeout sort; do
  command -v "$cmd" >/dev/null || { echo "Missing read-only check tool: $cmd" >&2; exit 1; }
done
failures=0
fail() { printf 'FAIL %s\n' "$*"; failures=$((failures + 1)); }
warn() { printf 'WARN %s\n' "$*"; }
pass() { printf 'PASS %s\n' "$*"; }
# os-release is the OS-provided shell-compatible metadata file.
source /etc/os-release
if [[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 24.04 && $(uname -m) == x86_64 ]]; then
  pass 'Ubuntu 24.04 x86_64'
else
  fail "Expected Ubuntu 24.04 x86_64; found ${ID:-unknown} ${VERSION_ID:-unknown} $(uname -m)"
fi
cpus=$(nproc)
mem_kib=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
free_kib=$(df -Pk /var | awk 'NR == 2 {print $4}')
# Project lab starting thresholds, not vendor minimums or capacity guarantees.
(( cpus >= 4 )) && pass "CPU: $cpus" || fail "CPU: $cpus (<4)"
(( cpus >= 8 )) || warn 'Joint Foreman/Compiler/DB candidate is 8 vCPU; size by measurements'
(( mem_kib >= 15 * 1024 * 1024 )) && pass 'Memory >=15 GiB' || fail 'Memory below project 16 GiB nominal starting floor'
(( mem_kib >= 30 * 1024 * 1024 )) || warn 'Joint-service candidate is 32 GiB nominal; check JVM/DB memory budget'
(( free_kib >= 50 * 1024 * 1024 )) && pass '/var free space >=50 GiB' || fail '/var free space <50 GiB'
actual=$(hostname -f 2>/dev/null || true)
[[ $actual == "$1" ]] && pass "Host FQDN: $actual" || fail "hostname -f is '$actual', expected '$1'"
local_ips=$(ip -o -4 addr show | awk '{sub(/\/.*/, "", $4); print $4}')
for name in "$@"; do
  addresses=$(timeout 10 getent ahostsv4 "$name" | awk '{print $1}' | sort -u) || addresses=''
  if [[ -z $addresses ]]; then fail "No IPv4 resolution within timeout: $name"; continue; fi
  matched=false
  while IFS= read -r address; do
    while IFS= read -r local_ip; do
      [[ $address == "$local_ip" ]] && matched=true
    done <<< "$local_ips"
  done <<< "$addresses"
  if [[ $matched == true ]]; then pass "DNS reaches a local interface: $name"; else fail "DNS does not resolve to this VM: $name"; fi
done
listeners=$(ss -H -lnt)
for port in 443 8140 8443 5432; do
  if awk -v port="$port" '$4 ~ (":" port "$") { found=1 } END { exit !found }' <<< "$listeners"; then
    fail "Port $port is already listening; inspect existing services before fresh installation"
  else
    pass "Port $port not already listening"
  fi
done
warn 'Manual: dedicated VM, time sync, forward/PTR DNS, SG/routes from Agent, repository access, PKI/SAN, backup destination'
warn 'This checks local IPv4 only; it does not verify inbound access, AWS resources, package compatibility or TLS'
printf 'Failed checks: %s\n' "$failures"
(( failures == 0 ))
