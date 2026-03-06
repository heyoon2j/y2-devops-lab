#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1

# 기본 패키지 목록
UBUNTU_DEFAULT_PACKAGES="jq git chrony net-tools nmap build-essential libssl-dev pkg-config bind-utils"
ROCKY_DEFAULT_PACKAGES="jq git wget bc bind-utils chrony net-tools nc"

# 설치되지 않은 패키지 목록을 담을 변수
NEED_PACKAGES=""

########################################
#           Ubuntu (Debian系)          #
########################################
apply_ubuntu() {
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y -qq
    sudo apt-get upgrade -y -qq

    echo "🔍 설치되지 않은 패키지 확인 중..."
    for pkg in $UBUNTU_DEFAULT_PACKAGES; do
      if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        NEED_PACKAGES="$NEED_PACKAGES $pkg"
      fi
    done

    if [ -n "$NEED_PACKAGES" ]; then
      echo "📥 설치할 패키지: $NEED_PACKAGES"
      sudo apt-get install -y -qq $NEED_PACKAGES
    else
      echo "✅ [Success] Installed all packages."
    fi
}

########################################
#         Rocky Linux (RHEL系)         #
########################################
apply_rocky() {
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
}


#######################################################
#####                  Execute                    #####
#######################################################
main() {
    case "$OS_ID" in
        rocky*)
            apply_rocky
            ;;
        ubuntu*)
            apply_ubuntu
            ;;
        *)
            echo "[ERROR] 지원되지 않는 OS: $OS_ID"
            exit 1
            ;;
    esac
}

main
exit 0 