#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1
SELINUX_CONFIG="/etc/selinux/config"

#######################################################
#####               Function - Main               #####
#######################################################
main() {
  echo "========== SELinux Setting Start =========="

  ## SELinux 설정
  ## ---------- Ubuntu 처리 ----------
  if [[ "$OS_ID" == "ubuntu" ]]; then
    echo "[INFO] Ubuntu - Check SELinux state"
    echo "[OK] Not use SELinux."
    exit 0

  ## ---------- Rocky 처리 ----------
  elif [[ "$OS_ID" == "rocky" || "$OS_ID" == "rocky8" || "$OS_ID" == "rocky9" ]]; then
    echo "[INFO] Rocky - Check SELinux state"
    CURRENT_STATE=$(sudo getenforce)
    if [[ "$CURRENT_STATE" == "Disabled" ]]; then
      echo "[OK] Already SELinux is disabled."
      exit 0
    fi

    echo "[INFO] SELinux를 일시적으로 Permissive 모드로 설정합니다."
    sudo setenforce 0 || echo "[Warning] Fail to setenforce (이미 Permissive이거나 Disabled일 수 있음)"

    echo "[INFO] $SELINUX_CONFIG 파일 수정 중..."
    if [ -f "$SELINUX_CONFIG" ]; then
      sudo cp "$SELINUX_CONFIG" "$SELINUX_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
      sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' "$SELINUX_CONFIG"
      echo "[OK] 영구 설정 변경 완료 ($SELINUX_CONFIG)"
    else
      echo "[ERROR] $SELINUX_CONFIG 파일이 존재하지 않습니다."
      exit 1
    fi

  ## ---------- 예외 처리 ----------
  else
    echo "[Info] ❌ 지원되지 않는 OS: $OS_ID"
    exit 2
  fi

  echo "[OK] SELinux가 비활성화 되었습니다. 재부팅 후 적용됩니다."
}


#######################################################
#####                                             #####
#######################################################
if [ -z "$OS_ID" ]; then
  echo "❗ 사용법: $0 <os: ubuntu|rocky8|rocky9>"
  exit 1
fi

main