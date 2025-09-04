#!/bin/bash

set -e  # 에러 발생 시 즉시 종료

#######################################################
#####           Detect OS & Set Variables        #####
#######################################################
if grep -qi 'ubuntu' /etc/os-release; then
  OS_TYPE="ubuntu"
  CLOUD_FILE="/etc/cloud/cloud.cfg.d/99-net-dns.yaml"
  TMP_CLOUD_FILE="/tmp/99-net-dns.yaml"
  RESOLV_FILE="/etc/resolv.conf"
  TMP_RESOLV_FILE="/tmp/resolv.conf"
elif grep -qi 'rocky' /etc/os-release; then
  OS_TYPE="rocky"
  CLOUD_FILE="/etc/cloud/cloud.cfg.d/99-net-dns.cfg"
  TMP_CLOUD_FILE="/tmp/99-net-dns.cfg"
  RESOLV_FILE="/etc/resolv.conf"
  TMP_RESOLV_FILE="/tmp/resolv.conf"
else
  echo "[ERROR] Unsupported OS."
  exit 1
fi

#######################################################
#####          Create tmp config contents        #####
#######################################################
mkdir -p "$(dirname "$CLOUD_FILE")"

if [ "$OS_TYPE" = "ubuntu" ]; then
  # cloud-init: resolv_conf로 resolv.conf 관리 + DHCP DNS 무시
  cat > "$TMP_CLOUD_FILE" << 'EOF'
#cloud-config
manage_resolv_conf: true
resolv_conf:
  nameservers: [10.44.100.100]
  searchdomains: [svc.cluster.local, cluster.local]
  options: {rotate: true, timeout: 1, attempts: 2}
network:
  version: 2
  renderer: networkd
  ethernets:
    allnics:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
EOF

  cat > "$TMP_RESOLV_FILE" << 'EOF'
# Managed by cloud-init resolv_conf (pre-apply)
nameserver 10.44.100.100
search svc.cluster.local cluster.local
options rotate timeout:1 attempts:2
EOF

elif [ "$OS_TYPE" = "rocky" ]; then
  cat > "$TMP_CLOUD_FILE" << 'EOF'
#cloud-config
network:
  version: 2
  ethernets:
    dhcp4: true
    dhcp4-overrides:
      use-dns: false
EOF

  cat > "$TMP_RESOLV_FILE" << EOF
# Managed manually
nameserver 10.44.100.100
search svc.cluster.local cluster.local
options rotate timeout:1 attempts:2
EOF
fi

#######################################################
#####              Apply to system               #####
#######################################################
echo "[INFO] Apply DNS via cloud-init config..."

mv -f "$TMP_CLOUD_FILE" "$CLOUD_FILE"
echo "[OK] Write cloud-init config to $CLOUD_FILE"

if [ -L "$RESOLV_FILE" ]; then
  mv -f "$RESOLV_FILE" "${RESOLV_FILE}.symlink.bak"
fi

mv -f "$TMP_RESOLV_FILE" "$RESOLV_FILE"
chmod 644 "$RESOLV_FILE"
echo "[OK] Write resolv.conf to $RESOLV_FILE"

if [ "$OS_TYPE" = "ubuntu" ]; then
  echo "[SUCCESS] Ubuntu DNS setup completed (cloud-init only, no netplan/resolved edits)."
elif [ "$OS_TYPE" = "rocky" ]; then
  echo "[SUCCESS] Rocky DNS setup completed (cloud-init only, no NetworkManager edits)."
fi
