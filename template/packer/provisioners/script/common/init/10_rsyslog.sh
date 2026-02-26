#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1

#######################################################
# Source common.sh
#######################################################
source /opt/packer/script/utils/common.sh

#######################################################
# RockyLinux 설치
#######################################################
function install_rsyslog_rocky() {
  echo "[*] OS: RockyLinux $OS_ID"

  get_repo_data foreman "/cloud/config/repo/rocky/infra-rsyslog.repo" "/etc/yum.repos.d/rsyslog.repo"

  install_packages rsyslog rsyslog-kafka
}

#######################################################
# Ubuntu 설치
#######################################################
function install_rsyslog_ubuntu() {
  echo "[*] OS: Ubuntu $OS_ID"
  local src_file="local"

  case "$OS_ID" in
    ubuntu20)
      src_file="/cloud/config/repo/ubuntu/ubuntu20-rsyslog.list"
      ;;
    ubuntu22)
      src_file="/cloud/config/repo/ubuntu/ubuntu22-rsyslog.list"
      ;;
    *)
      echo "❌ Unsupported Ubuntu version: $OS_ID"
      exit 1
      ;;
  esac

  get_repo_data foreman "$src_file" "/etc/apt/sources.list.d/rsyslog.list"

  install_packages rsyslog rsyslog-kafka
}

#######################################################
# Amazon Linux 설치
function install_rsyslog_amzn() {
  echo "[*] OS: Amazon Linux $OS_ID"

  if [[ "$OS_ID" != "amzn2023" ]]; then
    get_repo_data foreman "/cloud/config/repo/amzn/amzn2023-rsyslog.repo" "/etc/yum.repos.d/rsyslog.repo"
  fi

  sudo yum clean all
  sudo yum makecache
  install_packages rsyslog rsyslog-kafka
}


#######################################################
# Main
#######################################################
function main() {

  case "$OS_ID" in
    rocky*)
      install_rsyslog_rocky
      ;;
    ubuntu*)
      install_rsyslog_ubuntu
      ;;
    amzn*)
      install_rsyslog_amzn
      ;;
    *)
      echo "❌ Unsupported OS: $OS_ID"
      exit 1
      ;;
  esac

  echo "[+] rsyslog 및 rsyslog-kafka 설치 완료"
}

main