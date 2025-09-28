#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1

# 기본 패키지 목록
UBUNTU_DEFAULT_PACKAGES="jq git chrony python3.12 net-tools nmap build-essential libssl-dev pkg-config"
ROCKY_DEFAULT_PACKAGES="jq git wget bc bind-utils chrony python3.12 net-tools nc"

# 설치되지 않은 패키지 목록을 담을 변수
NEED_PACKAGES=""

#######################################################
#####               Function - Main               #####
#######################################################
main() {
  #####################################################
  # ---- Ubuntu 처리 ----
  if [[ "$OS_ID" == "ubuntu" ]]; then
    sudo apt update -y

    echo "🔍 설치되지 않은 패키지 확인 중..."
    for pkg in $UBUNTU_DEFAULT_PACKAGES; do
      if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        NEED_PACKAGES="$NEED_PACKAGES $pkg"
      fi
    done

    if [ -n "$NEED_PACKAGES" ]; then
      echo "📥 설치할 패키지: $NEED_PACKAGES"
      sudo apt install -y $NEED_PACKAGES
    else
      echo "✅ [Success] Installed all packages."
    fi

  #####################################################
  # ---- Rocky 8 & 9 공통 처리 ----
  elif [[ "$OS_ID" == "rocky8" || "$OS_ID" == "rocky9" ]]; then
    sudo yum update -y

    echo "🔍 설치되지 않은 패키지 확인 중..."
    for pkg in $ROCKY_DEFAULT_PACKAGES; do
      if ! command -v "$pkg" >/dev/null 2>&1; then
        NEED_PACKAGES="$NEED_PACKAGES $pkg"
      fi
    done

    if [ -n "$NEED_PACKAGES" ]; then
      echo "📥 설치할 패키지: $NEED_PACKAGES"
      sudo yum install -y $NEED_PACKAGES
    else
      echo "✅ [Success] Installed all packages."
    fi

  #####################################################
  # ---- 예외 처리 ----
  else
    echo "❌ 지원되지 않는 OS: $OS_ID"
    exit 2
  fi

  echo "✅ [$OS_ID] 패키지 설치 작업 완료"
}

#######################################################
#####                                             #####
#######################################################
if [ -z "$OS_ID" ]; then
  echo "❗ 사용법: $0 <os: ubuntu|rocky8|rocky9>"
  exit 1
fi

main