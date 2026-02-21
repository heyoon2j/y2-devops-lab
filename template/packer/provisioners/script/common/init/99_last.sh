#!/bin/bash
set -e

delete_default_users() {
  # 삭제 대상 계정 리스트
  USERS_TO_REMOVE=("ubuntu" "rocky")

  echo "🧹 사용자 계정 삭제 시작..."

  for USER in "${USERS_TO_REMOVE[@]}"; do
    echo "🔍 사용자 '$USER' 존재 여부 확인 중..."

    if id "$USER" &>/dev/null; then
      echo "✅ 사용자 '$USER' 존재함. 프로세스 종료 및 삭제 시작..."

      # 모든 프로세스를 강제 종료
      # sudo pkill -KILL -u "$USER" 2>/dev/null || true

      # 사용자 계정과 홈 디렉토리 삭제
      if sudo userdel -r "$USER"; then
        echo "✅ 사용자 '$USER' 삭제 완료"
      else
        echo "❌ 사용자 '$USER' 삭제 중 오류 발생"
      fi
    else
      echo "ℹ️ 사용자 '$USER'는 존재하지 않음"
    fi
  done

  echo
  echo "🔒 cloud-init 관련 sudoers 설정 비활성화 중..."

  SUDOERS_DIR="/etc/sudoers.d"

  # '90-cloud-init*' 이름으로 시작하는 파일만 백업
  for FILE in "$SUDOERS_DIR"/90-cloud-init*; do
    if [ -f "$FILE" ]; then
      echo "📁 파일 발견: $FILE → 백업"
      sudo mv "$FILE" "$FILE.$(date).bak"
    fi
  done

  echo "✅ cloud-init sudoers 설정 비활성화 완료"
}

main() {
  delete_default_users
}

main