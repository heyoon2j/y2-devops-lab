#!/bin/bash
set -e

#######################################################
# Configurable File Paths (변경 가능한 파일 경로)
#####################k##################################
REPO_DIR="/tmp/conf"                     # repo 파일들이 있는 디렉토리
ROCKY_REPO_FILE="rsyslog-rhel.repo"   # Rocky Linux용 repo 파일
UBUNTU20_LIST_FILE="rsyslog-ut20.list"   # Ubuntu 20.04용 list 파일
UBUNTU22_LIST_FILE="rsyslog-ut22.list"   # Ubuntu 22.04용 list 파일

#######################################################
# OS 판별
#######################################################
function detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_VER="${VERSION_ID%%.*}"
  else
    echo "Cannot detect OS. /etc/os-release not found."
    exit 1
  fi
}

#######################################################
# RockyLinux 설치
#######################################################
function install_rsyslog_rocky() {
  echo "[*] OS: RockyLinux $OS_VER"
  local src_file="${REPO_DIR}/${ROCKY_REPO_FILE}"
  local dest_path="/etc/yum.repos.d/${ROCKY_REPO_FILE}"

  if [ ! -f "$src_file" ]; then
    echo "❌ Repo file not found: $src_file"
    exit 1
  fi

  sudo cp "$src_file" "$dest_path"
  sudo yum clean all
  sudo yum makecache
  sudo yum install -y rsyslog rsyslog-kafka
}

#######################################################
# Ubuntu 설치
#######################################################
function install_rsyslog_ubuntu() {
  echo "[*] OS: Ubuntu $OS_VER"

  local src_file=""
  case "$OS_VER" in
    20)
      src_file="${REPO_DIR}/${UBUNTU20_LIST_FILE}"
      ;;
    22)
      src_file="${REPO_DIR}/${UBUNTU22_LIST_FILE}"
      ;;
    *)
      echo "❌ Unsupported Ubuntu version: $OS_VER"
      exit 1
      ;;
  esac

  local dest_path="/etc/apt/sources.list.d/rsyslog.list"

  if [ ! -f "$src_file" ]; then
    echo "❌ List file not found: $src_file"
    exit 1
  fi

  sudo cp "$src_file" "$dest_path"
  sudo apt-get update
  sudo apt-get install -y rsyslog rsyslog-kafka
}

#######################################################
# Main
#######################################################
function main() {
  detect_os

  case "$OS_ID" in
    rocky)
      install_rsyslog_rocky
      ;;
    ubuntu)
      install_rsyslog_ubuntu
      ;;
    *)
      echo "❌ Unsupported OS: $OS_ID"
      exit 1
      ;;
  esac

  echo "[+] rsyslog 및 rsyslog-kafka 설치 완료"
}

main