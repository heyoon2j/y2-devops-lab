#!/bin/bash

# ✅ 아키텍처 정보 수집
ARCH=$(${CMD_PREFIX} uname -m)

case "$ARCH" in
  x86_64) ARCH_TYPE="x86_64" ;;
  aarch64) ARCH_TYPE="arm64" ;;
  *) ARCH_TYPE="unknown" ;;
esac


# 결과 출력
echo $ARCH_TYPE