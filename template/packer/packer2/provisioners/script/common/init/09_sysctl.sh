#!/bin/bash

# 사용자가 만든 설정 파일 경로
SRC_SYSCTL_FILE="/tmp/packer/config/infra-sysctl.conf"
DST_SYSCTL_FILE="/etc/sysctl.d/99-sysctl.conf"

# 설정 파일 존재 여부 확인
if [ ! -f "$SRC_SYSCTL_FILE" ]; then
  echo "❌ 설정 파일이 존재하지 않습니다: $SRC_SYSCTL_FILE"
  exit 1
fi

echo "📄 $SRC_SYSCTL_FILE 내용을 $DST_SYSCTL_FILE 에 추가합니다..."

# 내용 추가
sudo cat "$SRC_SYSCTL_FILE" | sudo tee -a "$DST_SYSCTL_FILE" > /dev/null

## 권한 설정
sudo chmod 644 "$DST_SYSCTL_FILE"

echo "✅ 설정 파일 복사 완료. sysctl 설정을 영구 적용합니다..."
sudo sysctl --system

# 결과 확인
if [ $? -eq 0 ]; then
  echo "🎉 sysctl 설정이 성공적으로 영구 적용되었습니다."
else
  echo "❌ sysctl 설정 적용 중 오류가 발생했습니다."
  exit 2
fi
