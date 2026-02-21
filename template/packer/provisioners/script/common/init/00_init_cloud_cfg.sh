#!/bin/bash

set -e

CLOUD_CFG="/etc/cloud/cloud.cfg"
BACKUP_FILE="${CLOUD_CFG}.bak"

# 백업
sudo cp "$CLOUD_CFG" "$BACKUP_FILE"

# Use root
# disable_root 변경
sudo sed -i -E \
    -e 's/^( *disable_root: *)1/\10/' \
    -e 's/^( *disable_root: *)true/\1false/' \
    "$CLOUD_CFG"

# preserve_hostname 변경
sudo sed -i -E \
    -e 's/^( *preserve_hostname: *)true/\1false/' \
    -e 's/^( *preserve_hostname: *)1/\10/' \
    "$CLOUD_CFG"

# 기본 계정 삭제
sudo sed -i -z 's/users:[ \t\n]*- default/users: []/g' "$CLOUD_CFG"


echo "수정 완료: $CLOUD_CFG (백업: $BACKUP_FILE)"