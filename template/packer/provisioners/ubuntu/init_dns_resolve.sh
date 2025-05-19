#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
DNS_IP="10.44.100.100"

#######################################################
#####             Setting DNS Resolve             #####
#######################################################
echo "[1/6] systemd-resolved 활성화 및 resolv.conf 설정"
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "[2/6] NetworkManager에서 systemd-resolved 사용 설정"
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/99-global-dns.conf > /dev/null <<EOF
[main]
dns=systemd-resolved
EOF

## cloud-init
if [ -f /etc/NetworkManager/conf.d/99-cloud-init.conf ]; then
  sudo mv /etc/NetworkManager/conf.d/99-cloud-init.conf /etc/NetworkManager/conf.d/99-cloud-init.conf.bak
fi
##

sudo systemctl restart NetworkManager

echo "[3/6] systemd-resolved 전역 DNS 설정"
sudo sed -i 's/^#\?DNS=.*/DNS='"$DNS_IP"'/' /etc/systemd/resolved.conf
sudo sed -i 's/^#\?FallbackDNS=.*/FallbackDNS=/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

echo "[4/6] netplan YAML 구성 업데이트"
NETPLAN_FILE=$(find /etc/netplan -name "*.yaml" | head -n 1)
if [ -z "$NETPLAN_FILE" ]; then
  echo "ERROR: netplan 파일을 찾을 수 없습니다."
  exit 1
fi

sudo cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
INTERFACE=$(ip -o link show | awk -F': ' '!/lo/ {print $2; exit}')

sudo tee "$NETPLAN_FILE" > /dev/null <<EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    $INTERFACE:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses:
          - $DNS_IP
EOF

echo "[5/6] netplan 적용"
sudo netplan apply

echo "[6/6] 설정 확인"
resolvectl status | grep "DNS Servers"
echo
cat /etc/resolv.conf