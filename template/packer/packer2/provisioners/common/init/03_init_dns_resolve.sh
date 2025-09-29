#!/usr/bin/env bash
# Rocky & Ubuntu unified DNS setup
# - Rocky: NetworkManager + static /etc/resolv.conf (systemd-resolved 비활성)
# - Ubuntu: systemd-resolved 활성 + /etc/systemd/resolved.conf(DNS, Domains) 설정

set -Eeuo pipefail

########################################
#            Config (edit here)        #
########################################
DNS_IP="10.44.100.100"
DOMAINS="svc.cluster.local cluster.local"
OS_ID=$1

########################################
#           Pre-flight checks          #
########################################
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Run as root." >&2
  exit 1
fi

########################################
#           Common helpers             #
########################################
backup() {
  local f="$1"
  [[ -e "$f" || -L "$f" ]] || return 0
  sudo cp -a "$f" "${f}.bak.$(date +%Y%m%d%H%M%S)" || true
}

########################################
#         Rocky Linux (RHEL系)         #
########################################
apply_rocky() {
  echo "[INFO] Detected Rocky/RHEL family."

  local CLOUD_FILE="/etc/cloud/cloud.cfg.d/99-net-dns.cfg"
  local RESOLV_FILE="/etc/resolv.conf"

  # 1) cloud-init network v2 템플릿
  sudo mkdir -p "$(dirname "$CLOUD_FILE")"
  backup "$CLOUD_FILE"
  sudo tee "$CLOUD_FILE" > /dev/null <<'EOF'
#cloud-config
network:
  version: 2
  ethernets:
    dhcp4: true
    dhcp4-overrides:
      use-dns: false
EOF
  echo "[OK] cloud-init network config → $CLOUD_FILE"

  # 2) /etc/resolv.conf 고정값 적용
  # systemd-resolved 비활성화 (Rocky는 직접 resolv.conf 관리)
  if systemctl list-unit-files | grep -q '^systemd-resolved.service'; then
    sudo systemctl stop systemd-resolved || true
    sudo systemctl disable systemd-resolved || true
  fi

  # /etc/resolv.conf가 심볼릭이면 끊고 교체
  if [[ -L "$RESOLV_FILE" ]]; then
    backup "$RESOLV_FILE"
    sudo rm -f "$RESOLV_FILE"
  else
    backup "$RESOLV_FILE"
  fi

  sudo tee "$RESOLV_FILE" > /dev/null <<EOF
# Managed manually
nameserver ${DNS_IP}
search ${DOMAINS}
options rotate timeout:1 attempts:2
EOF
  sudo chmod 0644 "$RESOLV_FILE"
  echo "[OK] resolv.conf → $RESOLV_FILE"

  echo "[SUCCESS] Rocky DNS setup completed (cloud-init + static resolv.conf)."
}

########################################
#           Ubuntu (Debian系)          #
########################################
apply_ubuntu() {
  echo "[INFO] Detected Ubuntu/Debian family."

  local RESOLVED_FILE="/etc/systemd/resolved.conf"

  # resolved.conf 백업
  backup "$RESOLVED_FILE"
  sudo touch "$RESOLVED_FILE"

  # 기존 DNS= / Domains= 라인 제거(중복 방지, idempotent)
  sudo sed -i -e '/^[[:space:]]*DNS=.*/d' -e '/^[[:space:]]*Domains=.*/d' "$RESOLVED_FILE"

  # [Resolve] 섹션이 있으면 sed 'a\'로 두 줄 추가, 없으면 heredoc으로 새 섹션 생성
  if grep -q '^\[Resolve\]' "$RESOLVED_FILE"; then
    sudo sed -i "/^\[Resolve\]/a\\
DNS=${DNS_IP}\\
Domains=${DOMAINS}" "$RESOLVED_FILE"
  else
    sudo tee -a "$RESOLVED_FILE" > /dev/null <<EOF
[Resolve]
DNS=$DNS_IP
Domains=$DOMAINS
EOF
  fi
  echo "[OK] resolved.conf updated → $RESOLVED_FILE"

  # systemd-resolved 활성화 및 재시작
  sudo systemctl enable systemd-resolved || true
  sudo systemctl restart systemd-resolved

  # /etc/resolv.conf 가 stub로 연결되어 있지 않다면 교정
  if [[ ! -L /etc/resolv.conf ]] || [[ "$(readlink -f /etc/resolv.conf)" != "/run/systemd/resolve/stub-resolv.conf" ]]; then
    backup /etc/resolv.conf
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    echo "[OK] /etc/resolv.conf → stub-resolv.conf symlink set"
  fi

  echo "[SUCCESS] Ubuntu DNS setup completed (systemd-resolved)."
}

#######################################################
#####                  Execute                    #####
#######################################################
case "$OS_ID" in
  rocky8)  apply_rocky ;;
  rocky9)  apply_rocky ;;
  ubuntu20) apply_ubuntu ;;
  ubuntu22) apply_ubuntu ;;
esac