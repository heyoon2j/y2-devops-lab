#!/bin/bash
# Rocky9
# Rocky8
set -e

# 입력 인자: OS, REPO_CONTENT, REPO_FILE
OS_ID=$1
REPO_CONTENT=$2
REPO_FILE=$3

# 기본 경로 및 패키지
UBUNTU_DEFAULT_PACKAGES="curl vim net-tools wget git"

ROCKY_DEFAULT_REPO_PATH="/etc/yum.repos.d/infra-yum.repo"
ROCKY_RHEL_REPO_PATH="/etc/yum.repos.d/rhel-kpay-se.repo"
ROCKY_DEFAULT_PACKAGES="git wget bc bind utils systemd-resolved"

ROCKY8_DEFAULT_REPO_SOURCE="./infra-rocky8.repo"
ROCKY8_RHEL_REPO_SOURCE="./rhel-rocky8.repo"

ROCKY9_DEFAULT_REPO_SOURCE="./infra-rocky9.repo"
ROCKY9_RHEL_REPO_SOURCE="./rhel-rocky9.repo"

# 공통 함수 정의
apply_repo_file() {
  local source_file=$1
  local target_file=$2

  if [ ! -f "$source_file" ]; then
    echo "[ERROR] Source file not found: $source_file"
    return 1
  fi

  cat "$source_file" > "$target_file"
  if [ $? -eq 0 ]; then
    echo "[Success] '$source_file' → '$target_file' 적용 완료"
  else
    echo "[Failed] '$target_file' 적용 실패"
    return 1
  fi
}

# 사용법 안내
if [ -z "$OS_ID" ]; then
  echo "❗ 사용법: $0 <os: ubuntu|rocky8|rocky9> '<REPO 내용>'"
  exit 1
fi

#####################################################
# ---- Ubuntu 처리 ----
if [[ "$OS_ID" == "ubuntu" ]]; then
  echo "🔁 Ubuntu 저장소 초기화 중"
  cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F-%H%M%S)
  rm -f /etc/apt/sources.list.d/*.list
  echo "$REPO_CONTENT" > /etc/apt/sources.list
  # apt update -y

#####################################################
# ---- Rocky8 처리 ----
elif [[ "$OS_ID" == "rocky8" ]]; then
  echo "🔁 $OS_ID 저장소 초기화 중"

  DEFAULT_REPO_FILES=(/etc/yum.repos.d/Rocky-*.repo)
  for FILE in "${DEFAULT_REPO_FILES[@]}"; do
    echo "# Do not modify this file" > "$FILE"
    echo "[INFO] $FILE 주석 처리됨"
  done

  apply_repo_file "$ROCKY8_DEFAULT_REPO_SOURCE" "$ROCKY_DEFAULT_REPO_PATH"
  apply_repo_file "$ROCKY8_RHEL_REPO_SOURCE" "$ROCKY_RHEL_REPO_PATH"

  echo "📦 메타데이터 초기화 중..."
  dnf clean all
  # dnf makecache

#####################################################
# ---- Rocky9 처리 ----
elif [[ "$OS_ID" == "rocky9" ]]; then
  echo "🔁 $OS_ID 저장소 초기화 중"

  DEFAULT_REPO_FILES=(/etc/yum.repos.d/rocky*.repo)
  for FILE in "${DEFAULT_REPO_FILES[@]}"; do
    rm -f "$FILE"
    echo "[INFO] $FILE 삭제됨"
  done

  apply_repo_file "$ROCKY9_DEFAULT_REPO_SOURCE" "$ROCKY_DEFAULT_REPO_PATH"
  apply_repo_file "$ROCKY9_RHEL_REPO_SOURCE" "$ROCKY_RHEL_REPO_PATH"

  echo "📦 메타데이터 초기화 중..."
  dnf clean all
  # dnf makecache

#####################################################
# ---- 예외 처리 ----
else
  echo "❌ 지원되지 않는 OS: $OS_ID"
  exit 2
fi

echo "✅ [$OS_ID] 저장소 초기화 및 재설정 완료"
