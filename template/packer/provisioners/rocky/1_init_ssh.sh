#!/bin/bash
# Rocky9
# Rocky8
set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
CLOUD_CONFIG="/etc/cloud/cloud.cfg"

echo "[INFO] Updating SSHD config: $SSHD_CONFIG"

# PasswordAuthentication 설정 변경
if grep -q "^#*PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi

# SSH 서비스 재시작
echo "[INFO] Restarting sshd service"
systemctl restart sshd

echo "[완료] /etc/ssh/sshd_config 내 PasswordAuthentication 설정이 완료되었습니다."




echo "[INFO] Updating Cloud config file: $CLOUD_CONFIG"

# ssh_pwauth 값 변경
if grep -q "^ssh_pwauth:" "$CLOUD_CONFIG"; then
    sed -i 's/^ssh_pwauth:.*/ssh_pwauth:   true/' "$CLOUD_CONFIG"
    
else
    echo -e "\nssh_pwauth:   true" >> "$CLOUD_CONFIG"
fi

echo "[완료] $CLOUD_CONFIG 내 ssh_pwauth 설정이 완료되었습니다."

