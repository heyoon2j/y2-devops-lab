#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
SSHD_CONFIG="/etc/ssh/sshd_config"
CLOUD_CONFIG="/etc/cloud/cloud.cfg"
ALLOW_ROOT_IPS="10.10.10.10,203.0.113.5"

#######################################################
#####               Function - Main               #####
#######################################################
main() {
  echo "========== SSH Setting Start =========="

  ########################################################
  ## cloud-init 설정 - ssh_pwauth 값 변경
  echo "[INFO] Updating Cloud config file: $CLOUD_CONFIG"

  if grep -q "^ssh_pwauth:" "$CLOUD_CONFIG"; then
    sudo sed -i 's/ssh_pwauth:\s*0\s*/ssh_pwauth: 1/' "$CLOUD_CONFIG"
    sudo sed -i 's/ssh_pwauth:\s*false\s*/ssh_pwauth: true/' "$CLOUD_CONFIG"
  #else
  #    echo -e "\nssh_pwauth:   true" | sudo tee -a "$CLOUD_CONFIG"
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
      sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
  else
      echo "PasswordAuthentication yes" | sudo tee -a "$SSHD_CONFIG" > /dev/null
  fi
  echo "[OK] PasswordAuthentication Setting"

  # PublicKeyAuthentication 설정 변경
  if grep -q "^#*PubkeyAuthentication" "$SSHD_CONFIG"; then
      sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
  else
      echo "PubkeyAuthentication yes" | sudo tee -a "$SSHD_CONFIG" > /dev/null
  fi
  echo "[OK] PubkeyAuthentication Setting"

  ########################################################
  # PermitRootLogin: 기본은 막고, 특정 IP만 Match로 허용
  echo "[INFO] Configuring PermitRootLogin with Match Address"

  # 1) 전역 기본값: PermitRootLogin yes 주석 처리
  sudo sed -i 's/^PermitRootLogin yes/#PermitRootLogin yes/' "$SSHD_CONFIG"
  # if grep -q "^#*PermitRootLogin" "$SSHD_CONFIG"; then
  #    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
  # fi

  # 2) Match 블록 추가 (파일 맨 아래에 있어야 안전함)
  cat <<EOF | sudo tee -a "$SSHD_CONFIG" > /dev/null
PermitRootLogin no
Match Address $ALLOW_ROOT_IPS
    PermitRootLogin yes
EOF
  echo "[OK] PermitRootLogin 설정이 완료되었습니다. (특정 IP만 허용)"

  ########################################################
  # SSH 서비스 재시작
  sudo systemctl restart sshd
  echo "[OK] Restarting sshd service"

  echo "[OK] /etc/ssh/sshd_config 내 PasswordAuthentication 설정이 완료되었습니다."
}

#######################################################
#####                  Execute                    #####
#######################################################
main