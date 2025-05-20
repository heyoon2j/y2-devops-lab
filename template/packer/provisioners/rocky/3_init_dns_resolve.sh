#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
DNS_IP="10.44.100.100"

#######################################################
#####             Setting DNS Resolve             #####
#######################################################
echo "[1/5] systemd-resolved 활성화 및 resolv.conf 연결"
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf


echo "[2/5] NetworkManager에서 systemd-resolved 사용 설정"
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/99-global-dns.conf > /dev/null <<EOF
[main]
dns=systemd-resolved
EOF

# cloud-init
if [ -f /etc/NetworkManager/conf.d/99-cloud-init.conf ]; then
  sudo mv /etc/NetworkManager/conf.d/99-cloud-init.conf /etc/NetworkManager/conf.d/99-cloud-init.conf.bak
fi
##
 
sudo systemctl restart NetworkManager

echo "[3/5] systemd-resolved 전역 DNS 설정"
sudo sed -i 's/^#\?DNS=.*/DNS='"$DNS_IP"'/' /etc/systemd/resolved.conf
sudo sed -i 's/^#\?FallbackDNS=.*/FallbackDNS=/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

echo "[4/5] resolvectl 상태 확인"
resolvectl status | grep "DNS Servers"
echo
cat /etc/resolv.conf

echo "[5/5] 완료"
