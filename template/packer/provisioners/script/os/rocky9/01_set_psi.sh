#!/bin/bash
set -e

# PSI 활성화 스크립트 (Rocky9, BLS 비활성화 + sudo 적용 + 에러 종료 강화)
enable_psi_bootparam() {
  GRUB_CFG="/etc/default/grub"

  # GRUB_ENABLE_BLSCFG 처리
  if grep -q '^GRUB_ENABLE_BLSCFG=' "$GRUB_CFG"; then
    if grep -q '^GRUB_ENABLE_BLSCFG=true' "$GRUB_CFG"; then
      echo "[INFO] Changing GRUB_ENABLE_BLSCFG from true to false..."
      sudo sed -i 's/^GRUB_ENABLE_BLSCFG=true/GRUB_ENABLE_BLSCFG=false/' "$GRUB_CFG"
    else
      echo "[INFO] GRUB_ENABLE_BLSCFG already set to false."
    fi
  else
    echo "[INFO] Adding GRUB_ENABLE_BLSCFG=false..."
    echo 'GRUB_ENABLE_BLSCFG=false' | sudo tee -a "$GRUB_CFG" >/dev/null
  fi

  # psi=1 추가 (psi=0 -> psi=1 변경 또는 새로 추가)
  if grep -q "psi=1" "$GRUB_CFG"; then
    echo "[INFO] psi=1 already configured in GRUB."
  elif grep -q "psi=0" "$GRUB_CFG"; then
    echo "[INFO] Changing psi=0 to psi=1..."
    sudo sed -i 's/psi=0/psi=1/' "$GRUB_CFG"
  else
    echo "[INFO] Adding psi=1 to GRUB kernel params..."
    # GRUB_CMDLINE_LINUX 라인 존재 확인
    if ! grep -q '^GRUB_CMDLINE_LINUX=' "$GRUB_CFG"; then
      # 기존 GRUB_CMDLINE_LINUX에 psi=1 추가 (끝에서 닫는 따옴표 전에 추가)
      sudo sed -i 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 psi=1"/' "$GRUB_CFG"
    else
      echo "[INFO] GRUB_CMDLINE_LINUX not found, createing new entry..."
      echo 'GRUB_CMDLINE_LINUX="psi=1"' | sudo tee -a "$GRUB_CFG" >/dev/null
    fi
  fi

  # grub.cfg 재생성
  echo "[INFO] Updating grub.cfg..."
  if ! sudo grub2-mkconfig -o /boot/grub2/grub.cfg; then
    echo "[ERROR] grub2-mkconfig failed. Aborting."
    exit 1
  fi

  echo "[OK] GRUB updated. Please reboot to apply."
}

show_psi_status() {
  echo "=== PSI Status ==="
  for res in cpu memory io; do
    if [[ -f /proc/pressure/$res ]]; then
      echo "[$res]"
      cat /proc/pressure/$res
    fi
  done
}

main() {
  enable_psi_bootparam
  show_psi_status
}

main