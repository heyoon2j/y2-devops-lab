#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1
SELINUX_CONFIG="/etc/selinux/config"


########################################
#           Ubuntu (Debian系)          #
########################################
apply_ubuntu() {
    echo "[INFO] Ubuntu - Check SELinux state"
    echo "[OK] Not use SELinux."
    return 0
}

########################################
#           Ubuntu (Debian系)          #
########################################
apply_ubuntu() {
    echo "[INFO] Rocky - Check SELinux state"
    CURRENT_STATE=$(sudo getenforce)
    if [[ "$CURRENT_STATE" == "Disabled" ]]; then
      echo "[OK] Already SELinux is disabled."
      return 0
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
      return 1
    fi
    return 0
}


#######################################################
#####                  Execute                    #####
#######################################################
main() {
  echo "========== SELinux Setting Start =========="
  case "$OS_ID" in
    rocky8)  apply_rocky ;;
    rocky9)  apply_rocky ;;
    ubuntu20) apply_ubuntu ;;
    ubuntu22) apply_ubuntu ;;
    *) echo "[ERROR] 지원되지 않는 OS: $OS_ID" ; exit 2 ;;
  esac

  echo "[OK] 저장소 초기화 및 재설정 완료"
  exit 0
}