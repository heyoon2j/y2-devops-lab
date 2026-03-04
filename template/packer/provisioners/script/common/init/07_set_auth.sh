#!/bin/bash

set -e

#######################################################
#####                  User Setup                 #####
#######################################################
delete_default_users() {
  # 삭제 대상 계정 리스트
  USERS_TO_REMOVE=("ubuntu" "rocky" "ec2-user")

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

add_user_deploy() {
  SUDOERS_FILE="/etc/sudoers.d/deploy"

  # 사용자 존재 여부 확인
  if id "deploy" &>/dev/null; then
    echo "ℹ️  사용자 'deploy'이 이미 존재합니다."
    return 0
  fi

  # 그룹 생성
  if ! getent group "deploy" &>/dev/null; then
    echo "👥 그룹 생성 중: deploy"
    sudo groupadd -g 1000 deploy
  else
    echo "ℹ️  그룹 'deploy'이 이미 존재합니다."
  fi
  
  # 사용자 생성
  if ! id "deploy" &>/dev/null; then
    echo "👤 사용자 생성 중: deploy"
    sudo useradd -m -u 1000 -g deploy -s /bin/bash deploy
  else
    echo "ℹ️  사용자 'deploy'이 이미 존재합니다."
    sudo usermod -aG deploy deploy
  fi
  
  # 패스워드 설정
  echo "🔑 패스워드 설정 중: deploy"
  echo "deploy:test1234!@#$" | sudo chpasswd -e
  
  # 패스워드 만료일 설정 (무한대)
  sudo chage -E -1 -M 99999 deploy
  
  # sudoers 권한 추가
  echo "🔐 sudoers 권한 추가 중: deploy"
  sudo tee "$SUDOERS_FILE" > /dev/null <<EOF
deploy ALL=(ALL) NOPASSWD: /bin/systemctl,/usr/bin/systemctl,/usr/bin/docker
EOF
  sudo chmod 440 "$SUDOERS_FILE"
  echo "✅ [Success] User 'deploy' setup completed."
  return 0
}

add_user_mgt() {
  echo "🚧 [TODO] User 'mgt' setup is not implemented yet."
}

add_user_red() {
  echo "🚧 [TODO] User 'red' setup is not implemented yet."
}



#######################################################
#####               Function - Main               #####
#######################################################
main() {
  echo "🚀 Sudoers 설정 시작..."

  delete_default_users 
  add_user_deploy
  add_user_mgt
  add_user_red

  echo "✅ [Success] All sudoers setup completed."
}

#######################################################
#####                  Execute                    #####
#######################################################
main
exit 0