#!/bin/bash

set -e

#######################################################
#####            deploy User Setup                #####
#######################################################
add_user_deploy() {
  # 그룹 생성
  if ! getent group "deploy" &>/dev/null; then
    echo "👥 그룹 생성 중: deploy (gid: 2003)"
    sudo groupadd -g 2003 deploy
  else
    echo "ℹ️  그룹 'deploy'이 이미 존재합니다."
  fi
  
  # 사용자 생성
  if ! id "deploy" &>/dev/null; then
    echo "👤 사용자 생성 중: deploy (uid: 2003)"
    sudo useradd -m -u 2003 -g deploy -s /bin/bash deploy
  else
    echo "ℹ️  사용자 'deploy'이 이미 존재합니다."
    sudo usermod -aG deploy deploy
  fi
  
  # 패스워드 설정
  echo "🔑 패스워드 설정 중: deploy"
  echo "deploy:test1234!@#$" | sudo chpasswd
  
  # 패스워드 만료일 설정 (무한대)
  sudo chage -E -1 -M 99999 deploy
  
  # sudoers 권한 추가
  echo "🔐 sudoers 권한 추가 중: deploy"
  sudo tee /etc/sudoers.d/deploy > /dev/null <<EOF
deploy ALL=(ALL) NOPASSWD: /bin/systemctl,/usr/bin/systemctl,/usr/bin/docker
EOF
  sudo chmod 440 /etc/sudoers.d/deploy
  echo "✅ [Success] User 'deploy' setup completed."
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