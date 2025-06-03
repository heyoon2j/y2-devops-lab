#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
DNS_IP="10.44.100.100"


echo "S======== SSH Setting Start ==============="
#######################################################
#####             Setting DNS Resolve             #####
#######################################################
echo "[1/5] systemd-resolved 활성화 및 resolv.conf 연결"
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
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




#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
DNS_IP="10.44.100.100"

#######################################################
#####               OS Detection                  #####
#######################################################
source /etc/os-release
OS=$ID
VERSION=$VERSION_ID

echo "Detected OS: $OS $VERSION"

#######################################################
#####       Common: systemd-resolved 설정         #####
#######################################################w
echo "[1/5] systemd-resolved 활성화 및 resolv.conf 연결"
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "[2/5] systemd-resolved 전역 DNS 설정"
sudo sed -i 's/^#\?DNS=.*/DNS='"$DNS_IP"'/' /etc/systemd/resolved.conf
sudo sed -i 's/^#\?FallbackDNS=.*/FallbackDNS=/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

echo "[3/5] Network 서비스 - systemd-resolved 사용 설정"
#######################################################
#####             Ubuntu: netplan 설정            #####
#######################################################
if [[ "$OS" == "ubuntu" ]]; then
  echo "▶ Ubuntu detected: Configuring netplan"

  NETPLAN_FILE=$(find /etc/netplan -name "*.yaml" | head -n 1)
  if [ -z "$NETPLAN_FILE" ]; then
    echo "❌ Netplan 설정 파일을 찾을 수 없습니다."
    exit 1
  fi

  sudo cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
  INTERFACE=$(ip -o link show | awk -F': ' '!/lo/ {print $2; exit}')

  sudo tee "$NETPLAN_FILE" > /dev/null <<EOF
network:
  version: 2
  renderer: systemd-networkd
  ethernets:
    $INTERFACE:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses:
          - $DNS_IP
EOF

  sudo systemctl enable systemd-networkd
  sudo systemctl start systemd-networkd

  echo "[3/5] netplan 적용"
  sudo netplan apply

#######################################################
#####        Rocky: NetworkManager 설정           #####
#######################################################
elif [[ "$OS" == "rocky" ]]; then
  echo "▶ Rocky detected: Configuring NetworkManager"

  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo tee /etc/NetworkManager/conf.d/99-global-dns.conf > /dev/null <<EOF
[main]
dns=systemd-resolved
EOF

  if [ -f /etc/NetworkManager/conf.d/99-cloud-init.conf ]; then
    sudo mv /etc/NetworkManager/conf.d/99-cloud-init.conf /etc/NetworkManager/conf.d/99-cloud-init.conf.bak
  fi

  sudo systemctl restart NetworkManager

else
  echo "❌ Unsupported OS: $OS"
  exit 1
fi

#######################################################
#####                결과 확인                    #####
#######################################################
echo "[4/5] resolvectl 상태 확인"
resolvectl status | grep "DNS Servers"
echo
echo "[5/5] /etc/resolv.conf 확인"
cat /etc/resolv.conf



##############################################################################################################


#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
DNS_IP="10.44.100.100"

#######################################################
#####                  Function                   #####
#######################################################
setup_resolved() {
  sudo systemctl enable systemd-resolved
  sudo systemctl start systemd-resolved
  sudo cp /etc/resolv.conf /etc/resolv.conf.bak
  sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  sudo sed -i 's/^#\?DNS=.*/DNS='"$DNS_IP"'/' /etc/systemd/resolved.conf
  sudo sed -i 's/^#\?FallbackDNS=.*/FallbackDNS=/' /etc/systemd/resolved.conf
  sudo systemctl restart systemd-resolved
}

config_dns_ubuntu() {
  NETPLAN_FILE=$(find /etc/netplan -name "*.yaml" | head -n 1)
  if [ -z "$NETPLAN_FILE" ]; then
    echo "❌ Netplan 설정 파일을 찾을 수 없습니다."
    exit 1
  fi

  sudo cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
  INTERFACE=$(ip -o link show | awk -F': ' '!/lo/ {print $2; exit}')

  sudo tee "$NETPLAN_FILE" > /dev/null <<EOF
network:
  version: 2
  renderer: systemd-networkd
  ethernets:
    $INTERFACE:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses:
          - $DNS_IP
EOF

  sudo systemctl enable systemd-networkd
  sudo systemctl start systemd-networkd
  sudo netplan apply
}

config_dns_rocky() {
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo tee /etc/NetworkManager/conf.d/99-global-dns.conf > /dev/null <<EOF
[main]
dns=systemd-resolved
EOF

  if [ -f /etc/NetworkManager/conf.d/99-cloud-init.conf ]; then
    sudo mv /etc/NetworkManager/conf.d/99-cloud-init.conf /etc/NetworkManager/conf.d/99-cloud-init.conf.bak
  fi

  sudo systemctl restart NetworkManager
}

print_status() {
  resolvectl status | grep "DNS Servers"
  echo
  cat /etc/resolv.conf
}

#######################################################
#####              Function - Common              #####
#######################################################
print_failed_common() {
  echo "[INFO] Failed to execute script."
}

print_success_common() {
  echo "[INFO] Successfully executed the script."
}

#######################################################
#####                 Main 실행                   #####
#######################################################
main() {
  echo "=============== Setting DNS Start ==============="
  source /etc/os-release
  OS=$ID
  VERSION=$VERSION_ID

  echo "Detected OS: $OS $VERSION"

  echo "[INFO][1/3] systemd-resolved 설정 및 resolv.conf 연결"
  setup_resolved

  echo "[INFO][2/3] DNS 구성"
  if [[ "$OS" == "ubuntu" ]]; then
    echo
    echo "[INFO][---] netplan - Set Ubuntu DNS"
    config_dns_ubuntu

  elif [[ "$OS" == "rocky" ]]; then
    echo
    echo "[INFO][---] NetworkManager- Set Rocky DNS"
    config_dns_rocky

  else
    echo "[WARNING] ❌ 지원하지 않는 OS: $OS"
    print_failed_common
    exit 1
  fi

  echo "[INFO][3/3] 상태 확인"
  print_status

  print_success_common
}

main
