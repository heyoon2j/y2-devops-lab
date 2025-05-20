#!/bin/bash

# 입력 인자: OS, REPO_CONTENT
OS_ID=$1
REPO_CONTENT=$2
REPO_FILE=$3

# Ubuntu
UBUNTU_DEFAULT_REPO_PATH=""
UBUNTU_DEFAULT_PACKAGES="curl vim net-tools wget git"


# Rokcy
ROCKY_DEFAULT_REPO_PATH="/etc/yum.repos.d/infra-yum.repo"
ROKCY_RHEL_REPO_PATH="/etc/yum.repos.d/rhel-kpay-se.repo"
ROCKY_DEFAULT_PACKAGES="git wget bc bind utils systemd-resolved"

ROCKY8_DEFAULT_REPO_SOURCE="./infra-rocky8.repo"
ROCKY8_RHEL_REPO_SOURCE="./rhel-rocky8.repo"

ROCKY9_DEFAULT_REPO_SOURCE="./infra-rocky9.repo"
ROCKY9_RHEL_REPO_SOURCE="./rhel-rocky9.repo"


if [ -z "$OS_ID" ]; then #|| [ -z "$REPO_CONTENT" ] || [ -z "$REPO_FILE" ]; then
  # ./reset_system_repo.sh ubuntu \
  # "deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse"
  echo "❗ 사용법: $0 <os: ubuntu|rocky|rhel|centos> '<REPO 내용 문자열>'"
  exit 1
fi

#####################################################
# ---- Ubuntu 처리 ----
if [[ "$OS_ID" == "ubuntu" ]]; then
  
  echo "🔁 Ubuntu 저장소 초기화 중"

  # 백업
  cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F-%H%M%S)
  rm -f /etc/apt/sources.list.d/*.list

  # 저장소 내용 재설정
  echo "$REPO_CONTENT" > /etc/apt/sources.list

  # 적용
  apt update -y


#####################################################
# ---- Rocky8 처리 ----
elif [[ "$OS_ID" == "rocky8" ]]; then
  echo "🔁 $OS_ID 저장소 초기화 중"
  DEFAULT_REPO_FILES=(/etc/yum.repos.d/Rocky-*.repo)

  # 백업 및 정리
  if [ ${#DEFAULT_REPO_FILES[@]} -eq 0 ]; then
    echo "${REPO_DIR} 디렉토리에서 Rocky-*.repo 파일을 찾을 수 없습니다."
  
  else
    for FILE in "${DEFAULT_REPO_FILES[@]}"; do 
      echo "# Do not modify this file" > "$FILE"
      if [ $? -eq 0 ]; then
        echo "[Success] 파일 '$FILE'이 성공적으로 수정되었습니다."
      else
        echo "[Failed] 파일 '$FILE' 수정 중 오류가 발생했습니다."
      fi
  fi

  # 저장소 재설정
  cat "$ROCKY8_DEFAULT_REPO_SOURCE" > "$ROCKY_DEFAULT_REPO_PATH"
  cat "$ROCKY8_RHEL_REPO_SOURCE" > "$ROKCY_RHEL_REPO_PATH"

  if [ $? -eq 0 ]; then
    echo "[Success] 파일 '$FILE'이 성공적으로 수정되었습니다."
  else
    echo "[Failed] 파일 '$FILE' 수정 중 오류가 발생했습니다."
  fi


  # 적용
  echo "📦 메타데이터 초기화 중..."
  dnf clean all
  dnf makecache


#####################################################
# ---- Rocky9 처리 ----
elif [[ "$OS_ID" == "rocky9" ]]; then
  echo "🔁 $OS_ID 저장소 초기화 중"
  DEFAULT_REPO_FILES=(/etc/yum.repos.d/rocky-*.repo)

  # 백업 및 정리
  if [ ${#DEFAULT_REPO_FILES[@]} -eq 0 ]; then
    echo "${REPO_DIR} 디렉토리에서 rocky-*.repo 파일을 찾을 수 없습니다."
  
  else
    for FILE in "${DEFAULT_REPO_FILES[@]}"; do 
      rm "$FILE"
      if [ $? -eq 0 ]; the제
        echo "[Success] 파일 '$FILE'이 성공적으로 삭되었습니다."
      else
        echo "[Failed] 파일 '$FILE' 삭제 중 오류가 발생했습니다."
      fi
  fi

  # 저장소 재설정
  cat "$ROCKY9_DEFAULT_REPO_SOURCE" > "$ROCKY_DEFAULT_REPO_PATH"
  cat "$ROCKY9_RHEL_REPO_SOURCE" > "$ROKCY_RHEL_REPO_PATH"

  if [ $? -eq 0 ]; then
    echo "[Success] 파일 '$FILE'이 성공적으로 수정되었습니다."
  else
    echo "[Failed] 파일 '$FILE' 수정 중 오류가 발생했습니다."
  fi

  # 적용
  echo "📦 메타데이터 초기화 중..."
  dnf clean all
  dnf makecache


#####################################################
# ---- 예외 처리 ----
else
  echo "❌ 지원되지 않는 OS: $OS_ID"
  exit 2
fi

echo "✅ [$OS_ID] 저장소 초기화 및 재설정 완료"
