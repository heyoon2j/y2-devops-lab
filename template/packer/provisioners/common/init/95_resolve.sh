#!/bin/bash

# Rocky
# Network: NetworkManager
# DNS: static /etc/resolv.conf

set -e  # 에러 발생 시 즉시 종료

#######################################################
#####                 Variables                  #####
#######################################################
CLOUD_FILE="/etc/cloud/cloud.cfg.d/99-net-dns.cfg"
RESOLV_FILE="/etc/resolv.conf"

TMP_CLOUD_FILE="/tmp/99-net-dns.cfg"
TMP_RESOLV_FILE="/tmp/resolv.conf"


#######################################################
#####          Create tmp config contents        #####
#######################################################
# 1. cloud-init netplan 설정 템플릿
mkdir -p "$(dirname "$CLOUD_FILE")"

cat > "$TMP_CLOUD_FILE" << 'EOF'
#cloud-config
network:
  version: 2
  ethernets:
    dhcp4: true
    dhcp4-overrides:
      use-dns: false
EOF

# 2. resolv.conf 템플릿
cat > "$TMP_RESOLV_FILE" << EOF
# Managed manually
nameserver 10.44.100.100
search svc.cluster.local cluster.local
options rotate timeout:1 attempts:2
EOF

systemctl stop systemd-resolved
systemctl disable systemd-resolved

#######################################################
#####              Apply to system               #####
#######################################################
echo "[INFO] Start to apply configs..."

# cloud-init config 반영
mv -f "$TMP_CLOUD_FILE" "$CLOUD_FILE"
echo "[OK] Write cloud-init config to $CLOUD_FILE"

# /etc/resolv.conf 반영
if [ -L "$RESOLV_FILE" ]; then
  mv -f "$RESOLV_FILE" "${RESOLV_FILE}.symlink.bak"
fi

rm -f "$RESOLV_FILE"
mv -f "$TMP_RESOLV_FILE" "$RESOLV_FILE"
chmod 644 "$RESOLV_FILE"
echo "[OK] Write resolv.conf to $RESOLV_FILE"


echo "[SUCCESS] Rocky DNS setup completed (cloud-init only, no NetworkManager edits)."