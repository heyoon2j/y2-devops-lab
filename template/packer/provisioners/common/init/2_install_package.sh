#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1

# 기본 패키지 목록
UBUNTU_DEFAULT_PACKAGES="jq git chrony python3.12 net-tools build-essential libssl-dev pkg-config" # curl vim net-tools wget git"
ROCKY_DEFAULT_PACKAGES="jq git wget bc bind-utils systemd-resolved chrony python3.12"

# 설치되지 않은 패키지 목록을 담을 변수
NEED_PACKAGES=""




#######################################################
#####               Function - Main               #####
#######################################################

main() {
  #####################################################
  # ---- Ubuntu 처리 ----
  if [[ "$OS_ID" == "ubuntu" ]]; then
    apt update -y

    echo "🔍 설치되지 않은 패키지 확인 중..."
    for pkg in $UBUNTU_DEFAULT_PACKAGES; do
      if ! dpkg -s "$pkg"; then
        NEED_PACKAGES="$NEED_PACKAGES $pkg"
      fi
    done

    if [ -n "$NEED_PACKAGES" ]; then
      echo "📥 설치할 패키지: $NEED_PACKAGES"
      apt install -y $NEED_PACKAGES
    else
      echo "✅ 모든 패키지가 이미 설치되어 있습니다."
    fi

  #####################################################
  # ---- Rocky 8 & 9 공통 처리 ----
  elif [[ "$OS_ID" == "rocky8" || "$OS_ID" == "rocky9" ]]; then
    yum update -y

    echo "🔍 설치되지 않은 패키지 확인 중..."
    for pkg in $ROCKY_DEFAULT_PACKAGES; do
      if ! command -v "$pkg"; then
        NEED_PACKAGES="$NEED_PACKAGES $pkg"
      fi
    done

    if [ -n "$NEED_PACKAGES" ]; then
      echo "📥 설치할 패키지: $NEED_PACKAGES"
      yum install -y $NEED_PACKAGES
    else
      echo "✅ 모든 패키지가 이미 설치되어 있습니다."
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