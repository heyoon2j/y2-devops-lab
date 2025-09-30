#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1
ARCH=$2

CONF_DIR="/tmp/config/repo"

# 기본 경로
##### Ubuntu #####
UBUNTU_DEFAULT_REPO_PATH="/etc/apt/sources.list"
UBUNTU_EXTRA_REPO_PATH="/etc/apt/sources.list.d/ubuntu-extra.list"

UBUNTU2X_DEFAULT_REPO_PATH="${CONF_DIR}/ubuntu/${OS_ID}-${ARCH}-sources.list"
UBUNTU2X_EXTRA_REPO_PATH="${CONF_DIR}/ubuntu/${OS_ID}-extra.list"

##### Rocky #####
ROCKY_DEFAULT_REPO_PATH="/etc/yum.repos.d/infra-default.repo"
ROCKY_RHEL_REPO_PATH="/etc/yum.repos.d/infra-rhel.repo"

ROCKY_DEFAULT_REPO_SOURCE="${CONF_DIR}/rocky/infra-{$OS_ID}.repo"
ROCKY_RHEL_REPO_SOURCE="${CONF_DIR}/rocky/infra-rhel.repo"


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

#######################################################
#####               Function - Main               #####
#######################################################
main() {
  # ---- Ubuntu 처리 ----
  if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "ubuntu20" || "$OS_ID" == "ubuntu22"  ]]; then
    echo "🔁 Ubuntu 저장소 초기화 중"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F-%H%M%S)
    sudo rm -f /etc/apt/sources.list.d/*.list
    apply_repo_file "$UBUNTU2X_DEFAULT_REPO_PATH" "$UBUNTU_DEFAULT_REPO_PATH"
    apply_repo_file "$UBUNTU2X_EXTRA_REPO_PATH" "$UBUNTU_EXTRA_REPO_PATH"
    sudo apt update -y

  #####################################################
  # ---- Rocky 처리 ----
  elif [[ "$OS_ID" == "rocky8" || "$OS_ID" == "rocky9" ]]; then
    echo "🔁 $OS_ID 저장소 초기화 중"

    DEFAULT_REPO_FILES=(/etc/yum.repos.d/Rocky-*.repo)
    for FILE in "${DEFAULT_REPO_FILES[@]}"; do
      echo "# Do not modify this file" | sudo tee "$FILE" > /dev/null
      echo "[INFO] $FILE 주석 처리됨"
    done

    apply_repo_file "$ROCKY_DEFAULT_REPO_SOURCE" "$ROCKY_DEFAULT_REPO_PATH"
    apply_repo_file "$ROCKY_RHEL_REPO_SOURCE" "$ROCKY_RHEL_REPO_PATH"

    echo "📦 메타데이터 초기화 중..."
    sudo dnf clean all
    sudo dnf makecache

  #####################################################
  # ---- 예외 처리 ----
  else
    echo "❌ 지원되지 않는 OS: $OS_ID"
    exit 2
  fi

  echo "[OK] 저장소 초기화 및 재설정 완료"
}


#######################################################
#####                                             #####
#######################################################
main
