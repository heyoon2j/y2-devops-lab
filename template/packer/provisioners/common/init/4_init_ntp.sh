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
  cp "$CHRONY_CONF" "${CHRONY_CONF}.bak.$(date +%F-%H%M%S)"

  # 기존 server 또는 pool 라인을 주석 처리
  sed -i -E '/^[[:space:]]*(server|pool)[[:space:]]+/ s/^/#/' "$CHRONY_CONF"

  # 서버 설정 추가 (중복 방지를 위해 이미 추가된 경우에는 생략할 수도 있음)
  cat <<EOF >> "$CHRONY_CONF"

# Custom NTP servers
server test-ntp01.test.com iburst prefer maxpoll 8
server test-ntp02.test.com iburst maxpoll 8
server test-ntp03.test.com iburst maxpoll 8
EOF

  # systemd-timesyncd 비활성화 (Ubuntu 대응)
  if [[ "$OS_ID" == "ubuntu" ]]; then
    if systemctl is-active --quiet systemd-timesyncd; then
      systemctl stop systemd-timesyncd
      systemctl disable systemd-timesyncd
    fi
  fi

  # chronyd 재시작
  if systemctl is-active --quiet chronyd || systemctl is-active --quiet chrony; then
    systemctl restart chronyd || systemctl restart chrony
  else
    systemctl start chronyd || systemctl start chrony
  fi

  # 상태 확인
  echo "✅ NTP 동기화 상태:"
  chronyc sources || echo "chronyc 명령어를 사용할 수 없습니다."
}

#######################################################
#####                                             #####
#######################################################
if [ -z "$OS_ID" ]; then
  echo "❗ 사용법: $0 <os: ubuntu|rocky8|rocky9>"
  exit 1
fi

main