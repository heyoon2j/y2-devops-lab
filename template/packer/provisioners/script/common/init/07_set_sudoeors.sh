#!/bin/bash

set -e

#######################################################
#####                  User Setup                 #####
#######################################################
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

add_user_paymgt() {

}

add_user_red() {

}



#######################################################
#####               Function - Main               #####
#######################################################
main() {
  echo "🚀 Sudoers 설정 시작..."
  
  add_user_deploy
  
  echo "✅ [Success] All sudoers setup completed."
}

#######################################################
#####                  Execute                    #####
#######################################################
main
exit 0