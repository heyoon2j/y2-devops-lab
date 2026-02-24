#!/bin/bash

set -e

#######################################################
# Source common.sh
#######################################################
source /opt/packer/script/utils/common.sh

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1
ARCH=$2

CONF_DIR="/opt/packer/config"

# 기본 경로
##### Ubuntu #####
UBUNTU_DEFAULT_REPO_PATH="/etc/apt/sources.list"
UBUNTU_EXTRA_REPO_PATH="/etc/apt/sources.list.d/ubuntu-extra.list"

UBUNTU_DEFAULT_REPO_SOURCE="${CONF_DIR}/repo/ubuntu/${OS_ID}-${ARCH}-sources.list"
UBUNTU_EXTRA_REPO_SOURCE="${CONF_DIR}/repo/ubuntu/${OS_ID}-extra.list"

##### Rocky #####
ROCKY_DEFAULT_REPO_PATH="/etc/yum.repos.d/infra-default.repo"
ROCKY_RHEL_REPO_PATH="/etc/yum.repos.d/infra-rhel.repo"

ROCKY_DEFAULT_REPO_SOURCE="${CONF_DIR}/repo/rocky/infra-$OS_ID.repo"
ROCKY_RHEL_REPO_SOURCE="${CONF_DIR}/repo/rocky/infra-rhel.repo"
  

#######################################################
#####                  Function                   #####
#######################################################
apply_repo_file() {
  local source_file=$1
  local target_file=$2

  if [ ! -f "$source_file" ]; then
    echo "[ERROR] Source file not found: $source_file"
    return 1
  fi

  sudo cp "$source_file" "$target_file"
  if [ $? -eq 0 ]; then
    echo "[OK] '$source_file' → '$target_file' 적용 완료"
  else
    echo "[Failed] '$target_file' 적용 실패"
    return 1
  fi
}

########################################
#           Ubuntu (Debian系)          #
########################################
apply_ubuntu() {
  echo "🔁 $OS_ID 저장소 초기화 중"

  sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
  sudo rm -f /etc/apt/sources.list.d/*.list

  # sudo apt-get install -y wget

  # get_repo_data foreman "/cloud/config/repo/ubuntu/${OS_ID}-${ARCH}-sources.list" "$UBUNTU_DEFAULT_REPO_SOURCE"
  apply_repo_file "$UBUNTU_DEFAULT_REPO_SOURCE" "$UBUNTU_DEFAULT_REPO_PATH"

  # get_repo_data foreman "/cloud/config/repo/ubuntu/${OS_ID}-extra.list" "$UBUNTU_EXTRA_REPO_SOURCE"
  apply_repo_file "$UBUNTU_EXTRA_REPO_SOURCE" "$UBUNTU_EXTRA_REPO_PATH"

  # sudo apt-get update -y
}

########################################
#         Rocky Linux (RHEL系)         #
########################################
apply_rocky() {
  echo "🔁 $OS_ID 저장소 초기화 중"

  case "$OS_ID" in
    rocky8)
      DEFAULT_REPO_FILES=(/etc/yum.repos.d/Rocky-*.repo)
      ;;
    rocky9)
      DEFAULT_REPO_FILES=(/etc/yum.repos.d/rocky*.repo)
      ;;
    *) echo "[ERROR] 지원되지 않는 OS: $OS_ID" ; exit 2 ;;
  esac

  for FILE in "${DEFAULT_REPO_FILES[@]}"; do
    echo "# Do not modify this file" | sudo tee "$FILE" > /dev/null
    echo "[INFO] $FILE 주석 처리됨"
  done

  # sudo dnf install -y wget

  # get_repo_data foreman "/cloud/config/repo/rocky/infra-$OS_ID.repo" "$ROCKY_DEFAULT_REPO_PATH"
  apply_repo_file "$ROCKY_DEFAULT_REPO_SOURCE" "$ROCKY_DEFAULT_REPO_PATH"

  # get_repo_data foreman "/cloud/config/repo/rocky/infra-rhel.repo" "$ROCKY_RHEL_REPO_PATH"
  apply_repo_file "$ROCKY_RHEL_REPO_SOURCE" "$ROCKY_RHEL_REPO_PATH"

  echo "📦 메타데이터 초기화 중..."
  sudo dnf clean all
  sudo dnf makecache
}


#######################################################
#####                  Execute                    #####
#######################################################
main() {
  case "$OS_ID" in
    rocky*)   apply_rocky ;;
    #amazon*)  apply_rocky ;;
    ubuntu*)  apply_ubuntu ;;
    *) echo "[ERROR] 지원되지 않는 OS: $OS_ID" ; exit 1;;
  esac

  echo "[OK] 저장소 초기화 및 재설정 완료"
  exit 0
}

main