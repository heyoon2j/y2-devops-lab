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
  renderer: networkd
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
  sudo systemctl restart systemd-networkd
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

  sudo systemctl enable NetworkManager
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
