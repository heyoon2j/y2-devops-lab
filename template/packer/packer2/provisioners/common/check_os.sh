#!/bin/bash

if [[ ! -f /etc/os-release ]]; then
  echo "[ERROR] /etc/os-release not found" >&2
  exit 1
fi

. /etc/os-release

os_id="${ID,,}"
os_ver="${VERSION_ID%%.*}"

OS_ID=""

case "$os_id" in
  ubuntu)
    case "$os_ver" in
      20) OS_ID="ubuntu20" ;;
      22) OS_ID="ubuntu22" ;;
      *)  OS_ID="ubuntu"   ;;
    esac
    ;;
  rocky|rhel|centos|almalinux|fedora)
    case "$os_ver" in
      8) OS_ID="rocky8" ;;
      9) OS_ID="rocky9" ;;
      *) OS_ID="rocky"  ;;
    esac
    ;;
  *)
    if [[ -f /etc/redhat-release ]]; then
      if grep -q "release 9" /etc/redhat-release; then
        OS_ID="rocky9"
      elif grep -q "release 8" /etc/redhat-release; then
        OS_ID="rocky8"
      else
        OS_ID="rocky"
      fi
    else
      OS_ID="unknown"
    fi
    ;;
esac

if [[ "$OS_ID" == "unknown" ]]; then
  echo "[ERROR] Unsupported OS (ID=${ID:-unknown}, VERSION_ID=${VERSION_ID:-unknown})" >&2
  exit 2
fi

# 결과 출력
echo "$OS_ID"
