#!/usr/bin/env bash
# Repository/package stages need Bash+jq only. Configuration uses OpenVox's Ruby.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
action=${1:-}; shift || true
usage() { echo "Usage: $action --config INPUT.json [--apply] (default: read-only plan)"; }
input=; apply=false
while (($#)); do
  case $1 in
    --help|-h) usage; exit 0;;
    --config) [[ $# -ge 2 ]] || { usage >&2; exit 1; }; input=$2; shift 2;;
    --apply) apply=true; shift;;
    *) echo "Unknown argument: $1" >&2; exit 1;;
  esac
done
[[ -n $input && -f $input ]] || { usage >&2; exit 1; }
case $action in
  *-config|ca-init)
    ruby_bin=${FOREMAN_BOOTSTRAP_RUBY:-/opt/puppetlabs/puppet/bin/ruby}
    if [[ ! -x $ruby_bin ]]; then ruby_bin=$(command -v ruby || true); fi
    [[ -n $ruby_bin && -x $ruby_bin ]] || { echo 'Install OpenVox Agent first (Ruby runtime); no Python required' >&2; exit 1; }
    args=("$root/lib/configure.rb" "$action" --config "$input")
    if $apply; then args+=(--apply); fi
    exec "$ruby_bin" "${args[@]}";;
  foreman-repo|openvox-repo|agent-repo|foreman-install|openvox-install|agent-install) ;;
  *) echo 'Unknown stage' >&2; exit 1;;
esac
command -v jq >/dev/null || { echo 'jq is required for repository/package stages' >&2; exit 1; }
jq -e 'type=="object"' "$input" >/dev/null
get() { jq -r "$1 // empty" "$input"; }
os_id=$(get .os.id); os_version=$(get .os.version); arch=$(get .os.architecture)
errors=(); operations='[]'
error() { errors+=("$1"); }
add() { operations=$(jq -c --argjson item "$1" '. + [$item]' <<<"$operations"); }
case "$os_id/$os_version" in ubuntu/22.04|ubuntu/24.04|ubuntu/26.04|rocky/8|rocky/9|amzn/2|amzn/2023) ;; *) error 'Unsupported OS/version';; esac
[[ $arch == x86_64 || $arch == aarch64 ]] || error 'Architecture must be x86_64 or aarch64'
if [[ $action != agent-* && $os_id/$os_version/$arch != ubuntu/24.04/x86_64 ]]; then error 'Management server requires Ubuntu 24.04 x86_64'; fi
if [[ $action == *-repo ]]; then
  product=openvox; [[ $action != foreman-repo ]] || product=foreman
  fingerprint=$(get ".repository_keys.$product")
  [[ $fingerprint =~ ^[A-F0-9]{40}$ ]] || error "Set valid repository_keys.$product primary fingerprint"
  series=9; [[ $os_id/$os_version != amzn/2 ]] || series=8
  key_path=/usr/share/keyrings/$product-bootstrap.gpg
  key_url=https://apt.voxpupuli.org/GPG-KEY-openvox.pub
  [[ $product != foreman ]] || key_url=https://deb.theforeman.org/foreman.asc
  family=el; [[ $os_id != amzn ]] || family=amazon
  if [[ $os_id == ubuntu ]]; then
    source=config/repos/apt/$product.sources.tmpl
    destination=/etc/apt/sources.list.d/$product-bootstrap.sources
    rpm=false
  else
    source=config/repos/yum/openvox.repo.tmpl
    destination=/etc/yum.repos.d/openvox-bootstrap.repo
    key_url=https://yum.voxpupuli.org/GPG-KEY-openvox.pub
    rpm=true
  fi
  content=$(cat "$root/$source")
  content=${content//\{\{key_path\}\}/$key_path}
  content=${content//\{\{series\}\}/$series}
  content=${content//\{\{os_version\}\}/$os_version}
  content=${content//\{\{rpm_family\}\}/$family}
  [[ $content != *'{{'* && $content != *'}}'* ]] || error 'Unknown repository template variable'
  add "$(jq -nc --arg url "$key_url" --arg fingerprint "$fingerprint" --arg path "$key_path" --argjson rpm "$rpm" '{type:"key",url:$url,fingerprint:$fingerprint,path:$path,rpm:$rpm}')"
  add "$(jq -nc --arg path "$destination" --arg content "$content" --arg source "$source" '{type:"file",path:$path,content:($content+"\n"),source:$source,mode:420}')"
  if [[ $os_id == ubuntu ]]; then add '{"type":"command","argv":["apt-get","update"]}'; fi
else
  case $action in foreman-install) package_file=foreman.json;; openvox-install) package_file=openvox-server.json;; agent-install) package_file=openvox-agent.json;; esac
  pins='{}'
  mapfile -t packages < <(jq -er '.[]' "$root/config/packages/$package_file")
  ((${#packages[@]})) || error 'Package list is empty'
  for package in "${packages[@]}"; do
    [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || { error 'Invalid package list'; continue; }
    pin=$(get ".package_versions[\"$package\"]")
    [[ $pin =~ ^[A-Za-z0-9.+:~_-]+$ ]] || error "Set valid package_versions.$package"
    baseline_key=$package
    if [[ $package == openvox-agent && $os_id/$os_version == amzn/2 ]]; then baseline_key=amazon2-agent; fi
    baseline=$(jq -r --arg key "$baseline_key" '.[$key] // empty' "$root/config/versions.json")
    if [[ -n $baseline && $pin != "$baseline" && $pin != "$baseline-"* ]]; then error "Pin $package to upstream $baseline plus distribution revision"; fi
    pins=$(jq -c --arg key "$package" --arg value "$pin" '. + {($key):$value}' <<<"$pins")
  done
  add "$(jq -nc --arg os "$os_id" --arg version "$os_version" --argjson pins "$pins" '{type:"packages",os:$os,version:$version,pins:$pins}')"
fi
unresolved='[]'
for issue in "${errors[@]}"; do unresolved=$(jq -c --arg issue "$issue" '. + [$issue]' <<<"$unresolved"); done
if ! $apply; then jq -n --arg action "$action" --argjson unresolved "$unresolved" --argjson operations "$operations" '{action:$action,mode:"plan",unresolved:$unresolved,operations:$operations}'; exit 0; fi
((${#errors[@]}==0)) || { printf '%s\n' "${errors[@]}" >&2; exit 1; }
[[ $EUID == 0 ]] || { echo '--apply must run as root on the target' >&2; exit 1; }
# Read os-release as data, never source an input file as shell code.
actual_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')
actual_version=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')
[[ $os_id != rocky ]] || actual_version=${actual_version%%.*}
[[ $actual_id/$actual_version/$(uname -m) == "$os_id/$os_version/$arch" ]] || { echo 'Target OS does not match input' >&2; exit 1; }
exec 9>/run/lock/foreman-openvox-bootstrap.lock
flock -n 9 || { echo 'Another bootstrap is running' >&2; exit 1; }
tmp=$(mktemp -d); policy_owned=false
cleanup() { if $policy_owned; then rm -f /usr/sbin/policy-rc.d; fi; rm -rf -- "$tmp"; }
trap cleanup EXIT
atomic() {
  local target=$1 source_file=$2
  [[ ! -L $target ]] || { echo "Refusing symlink: $target" >&2; exit 1; }
  install -d -m 0755 "$(dirname -- "$target")"
  local staged; staged=$(mktemp "$(dirname -- "$target")/.bootstrap-XXXXXX")
  install -m 0644 -- "$source_file" "$staged"; mv -f -- "$staged" "$target"
}
if [[ $action == *-repo ]]; then
  if [[ $os_id == ubuntu ]]; then
    legacy=${destination%.sources}.list
    [[ ! -e $legacy && ! -L $legacy ]] || { echo "Review legacy repository first: $legacy" >&2; exit 1; }
  fi
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --max-time 30 --max-filesize 1048576 "$key_url" -o "$tmp/key.asc"
  install -d -m 0700 "$tmp/gnupg"
  GNUPGHOME=$tmp/gnupg gpg --batch --show-keys --with-colons "$tmp/key.asc" > "$tmp/key-info"
  actual=$(awk -F: '$1=="pub"{primary=1;next} $1=="sub"{primary=0} $1=="fpr"&&primary{print $10;primary=0}' "$tmp/key-info")
  [[ $actual == "$fingerprint" ]] || { echo 'Primary key fingerprint mismatch' >&2; exit 1; }
  if $rpm; then
    atomic "$key_path.asc" "$tmp/key.asc"; timeout 120 rpm --import "$key_path.asc"
  else
    GNUPGHOME=$tmp/gnupg gpg --batch --dearmor --output "$tmp/key.gpg" "$tmp/key.asc"
    atomic "$key_path" "$tmp/key.gpg"
  fi
  printf '%s\n' "$content" > "$tmp/repository"; atomic "$destination" "$tmp/repository"
  if [[ $os_id == ubuntu ]]; then timeout 600 apt-get update; fi
else
  for legacy in puppet-agent puppetserver puppet-enterprise; do
    if [[ $os_id == ubuntu ]]; then
      status=$(dpkg-query -W '-f=${db:Status-Status}' "$legacy" 2>/dev/null || true)
      [[ $status != installed ]] || { echo "Explicit migration required for $legacy" >&2; exit 1; }
    elif rpm -q "$legacy" >/dev/null 2>&1; then echo "Explicit migration required for $legacy" >&2; exit 1; fi
  done
  args=()
  for package in "${packages[@]}"; do
    pin=$(jq -r --arg key "$package" '.[$key]' <<<"$pins")
    if [[ $os_id == ubuntu ]]; then args+=("$package=$pin"); else args+=("$package-$pin"); fi
  done
  if [[ $os_id == ubuntu ]]; then
    if [[ ! -e /usr/sbin/policy-rc.d && ! -L /usr/sbin/policy-rc.d ]]; then
      printf '#!/bin/sh\nexit 101\n' > "$tmp/policy"; install -m 0755 "$tmp/policy" /usr/sbin/policy-rc.d; policy_owned=true
    fi
    timeout 600 apt-get update
    DEBIAN_FRONTEND=noninteractive timeout 3600 apt-get install -y --no-remove "${args[@]}"
  else
    manager=dnf; [[ $os_id/$os_version != amzn/2 ]] || manager=yum
    timeout 3600 "$manager" install -y "${args[@]}"
  fi
  for package in "${packages[@]}"; do
    expected=$(jq -r --arg key "$package" '.[$key]' <<<"$pins")
    if [[ $os_id == ubuntu ]]; then actual=$(dpkg-query -W '-f=${Version}' "$package"); else actual=$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$package"); fi
    [[ $actual == "$expected" ]] || { echo "Installed version differs: $package" >&2; exit 1; }
  done
fi
