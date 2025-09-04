#!/bin/bash

# Ubuntu
# Network: systemd-networkd
# DNS: systemd-resolved

set -e  # 에러 발생 시 즉시 종료

#######################################################
#####                 Variables                  #####
######################################################
#CLOUD_FILE="/etc/cloud/cloud.cfg.d/99-net-dns.cfg"
RESOLV_FILE="/etc/systemd/resolved.conf"

#TMP_CLOUD_FILE="/tmp/99-net-dns.cfg"
DNS_IP="10.44.100.100"
DOMAINS="svc.cluster.local cluster.local"

#######################################################
#####          Create tmp config contents        #####
#######################################################
# cloud-init: resolv_conf로 resolv.conf 관리 + DHCP DNS 무시

#cat > "$TMP_CLOUD_FILE" << 'EOF'
##cloud-config
#network:
#  version: 2
#  ethernets:
#    dhcp4: true
#    dhcp4-overrides:
#      use-dns: false
#EOF


#######################################################
#####              Apply to system               #####
#######################################################
echo "[INFO] Apply DNS via cloud-init resolv_conf..."

# cloud-init 설정 배치
#mv -f "$TMP_CLOUD_FILE" "$CLOUD_FILE"
#echo "[OK] Write cloud-init config to $CLOUD_FILE"


# /etc/systemd/resolved.conf
## 기존 DNS, Domains 라인을 주석 처리
sed -i 's/^\s*DNS=.*$/# &/' "$RESOLV_FILE"
sed -i 's/^\s*Domains=.*$/# &/' "$RESOLV_FILE"

## [Resolve] 바로 뒤에 새 DNS, Domains 삽입
sed -i "/^\[Resolve\]/a DNS=${DNS_IP}\nDomains=${DOMAINS}" "$RESOLV_FILE"
echo "[OK] Write resolved.conf to $RESOLV_FILE (immediate)"

systemctl enable systemd-resolved
systemctl restart systemd-resolved


echo "[SUCCESS] Ubuntu DNS setup completed (cloud-init, resolved edits)."
