#!/bin/bash
# Rocky9
# Rocky8
set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
CLOUD_CONFIG="/etc/cloud/cloud.cfg"


echo "======== SSH Setting Start ========"
echo "[INFO] Updating SSHD config: $SSHD_CONFIG"

# PasswordAuthentication 설정 변경
if grep -q "^#*PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi


if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
  sudo mv /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak
  echo "[OK] Disable cloud-init - SSHD config"
fi


# SSH 서비스 재시작
systemctl restart sshd
echo "[OK] Restarting sshd service"

echo "[OK] /etc/ssh/sshd_config 내 PasswordAuthentication 설정이 완료되었습니다."

########################################################
# Cloud Init 설정
echo "[INFO] Updating Cloud config file: $CLOUD_CONFIG"

# ssh_pwauth 값 변경
if grep -q "^ssh_pwauth:" "$CLOUD_CONFIG"; then
    #sed -i 's/^ssh_pwauth:.*/ssh_pwauth:   true/' "$CLOUD_CONFIG"
    sed -i 's/ssh_pwauth:\s*0\s*/ssh_pwauth: 1/' "$CLOUD_CONFIG"
    sed -i 's/ssh_pwauth:\s*false\s*/ssh_pwauth: true/' "$CLOUD_CONFIG"
#else
#    echo -e "\nssh_pwauth:   true" >> "$CLOUD_CONFIG"
fi

echo "[완료] $CLOUD_CONFIG 내 ssh_pwauth 설정이 완료되었습니다."

