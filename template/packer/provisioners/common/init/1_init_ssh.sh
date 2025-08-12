#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
OS_ID=$1
SSHD_CONFIG="/etc/ssh/sshd_config"
CLOUD_CONFIG="/etc/cloud/cloud.cfg"


#######################################################
#####               Function - Main               #####
#######################################################
main() {
  echo "========== SSH Setting Start =========="

  ########################################################
  ## cloud-init 설정 - ssh_pwauth 값 변경
  echo "[INFO] Updating Cloud config file: $CLOUD_CONFIG"

  if grep -q "^ssh_pwauth:" "$CLOUD_CONFIG"; then
      #sed -i 's/^ssh_pwauth:.*/ssh_pwauth:   true/' "$CLOUD_CONFIG"
      sed -i 's/ssh_pwauth:\s*0\s*/ssh_pwauth: 1/' "$CLOUD_CONFIG"
      sed -i 's/ssh_pwauth:\s*false\s*/ssh_pwauth: true/' "$CLOUD_CONFIG"
  #else
  #    echo -e "\nssh_pwauth:   true" >> "$CLOUD_CONFIG"
  fi
  echo "[OK] $CLOUD_CONFIG 내 ssh_pwauth 설정이 완료되었습니다."


  ## cloud-init sshd 파일 변경
  if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
    sudo mv /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak
    echo "[OK] Disable cloud-init - SSHD config"
  fi

  if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
    sudo mv /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/ssh/sshd_config.d/50-cloud-init.conf.bak
    echo "[OK] Disable cloud-init - SSHD config"
  fi

  ########################################################
  # PasswordAuthentication 설정 변경
  echo "[INFO] Updating SSHD config: $SSHD_CONFIG"
  if grep -q "^#*PasswordAuthentication" "$SSHD_CONFIG"; then
      sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
  else
      echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
  fi

  # PermitRootLogin 설정 변경
  if grep -q "^#*PermitRootLogin" "$SSHD_CONFIG"; then
      sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
  else
      echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
  fi

  # PubkeyAuthentication 설정 변경
  if grep -q "^#*PubkeyAuthentication" "$SSHD_CONFIG"; then
      sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
  else
      echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
  fi


  # SSH 서비스 재시작
  systemctl restart sshd
  echo "[OK] Restarting sshd service"

  echo "[OK] /etc/ssh/sshd_config 내 PasswordAuthentication 설정이 완료되었습니다."

}

#######################################################
#####                                             #####
#######################################################
if [ -z "$OS_ID" ]; then
  echo "❗ 사용법: $0 <os: ubuntu|rocky8|rocky9>"
  exit 1
fi

main