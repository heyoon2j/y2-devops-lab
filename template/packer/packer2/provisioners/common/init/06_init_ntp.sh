#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1

#######################################################
#####               Function - Main               #####
#######################################################
main() {
  # 배포판에 따라 chrony.conf 경로 결정
  if [ -f /etc/chrony/chrony.conf ]; then
    CHRONY_CONF="/etc/chrony/chrony.conf"
  else
    CHRONY_CONF="/etc/chrony.conf"
  fi

  # 백업
  sudo cp "$CHRONY_CONF" "${CHRONY_CONF}.bak.$(date +%F-%H%M%S)"

  # 기존 server 또는 pool 라인을 주석 처리
  sudo sed -i -E '/^[[:space:]]*(server|pool)[[:space:]]+/ s/^/#/' "$CHRONY_CONF"

  # 서버 설정 추가
  sudo tee -a "$CHRONY_CONF" > /dev/null <<EOF

# Custom NTP servers
server test-ntp01.test.com iburst prefer maxpoll 8
server test-ntp02.test.com iburst maxpoll 8
server test-ntp03.test.com iburst maxpoll 8
EOF

  # systemd-timesyncd 비활성화 (Ubuntu 대응)
  if [[ "$OS_ID" == "ubuntu" ]]; then
    if systemctl is-active --quiet systemd-timesyncd; then
      sudo systemctl stop systemd-timesyncd
      sudo systemctl disable systemd-timesyncd
    fi
  fi

  # chronyd 재시작 (서비스 존재 여부에 따라 처리)
  if systemctl is-active --quiet chronyd || systemctl is-active --quiet chrony; then
    sudo systemctl restart chronyd || sudo systemctl restart chrony
  else
    sudo systemctl start chronyd || sudo systemctl start chrony
  fi

  sudo systemctl enable chronyd || sudo systemctl enable chrony

  # 상태 확인
  echo "✅ [Success] NTP Synchronization Setting."
  chronyc sources || echo "chronyc 명령어를 사용할 수 없습니다."

  # Timezone 설정
  sudo timedatectl set-timezone Asia/Seoul
  echo "✅ [Success] Timezone set to Asia/Seoul."  
}

#######################################################
#####                                             #####
#######################################################
if [ -z "$OS_ID" ]; then
  echo "❗ 사용법: $0 <os: ubuntu|rocky8|rocky9>"
  exit 1
fi

main