#!/bin/bash
# Rocky9
# Rocky8

set -e

echo "[INFO] SELinux 상태 확인 중..."
CURRENT_STATE=$(getenforce)

if [[ "$CURRENT_STATE" == "Disabled" ]]; then
  echo "[OK] 이미 SELinux는 비활성화 상태입니다."
  exit 0
fi

echo "[INFO] SELinux를 일시적으로 Permissive 모드로 설정합니다."
sudo setenforce 0 || echo "[경고] setenforce 실패 (이미 Permissive이거나 Disabled일 수 있음)"

echo "[INFO] /etc/selinux/config 파일 수정 중..."
if [ -f /etc/selinux/config ]; then
  sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
  echo "[OK] 영구 설정 변경 완료 (/etc/selinux/config)"
else
  echo "[ERROR] /etc/selinux/config 파일이 존재하지 않습니다."
  exit 1
fi

echo "[완료] SELinux가 비활성화 되었습니다. 재부팅 후 적용됩니다."