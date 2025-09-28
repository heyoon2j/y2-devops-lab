#!/bin/bash
set -e

#######################################################
#####                Local Variable               #####
#######################################################
GITHUB_URL="https://github.test.com/abc-test/aa.git"
BRANCH_NAME="dev-test"
GITHUB_USER="your-username"               # 사용자명
GITHUB_TOKEN="your-personal-access-token" # PAT
MY_PATH="/opt/"

PYTHON_VERSION="3.12.6"
PYTHON_SHORT_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f1,2)
PYTHON_BIN="/usr/local/bin/python${PYTHON_SHORT_VERSION}"
PYTHON_SRC_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

PIP_INDEX_URL="https://pypi.yourcompany.com/simple"
PIP_TRUST_HOST="pypi.yourcompany.com"

# 설치할 pip 패키지 목록 (필요 시 수정)
PIP_PACKAGES="" # "requests flask"

#######################################################
#####               Function - Git Clone          #####
#######################################################
clone_repo() {
  echo "========== Git Clone Start =========="

  cd "$MY_PATH"
  AUTH_URL=$(echo "$GITHUB_URL" | sed "s#https://#https://$GITHUB_USER:$GITHUB_TOKEN@#")
  git clone --branch "$BRANCH_NAME" "$AUTH_URL"
}

#######################################################
#####           Function - Python Build            #####
#######################################################
build_python() {
  echo "========== Python Build Start =========="

  # 빌드 의존성 설치
  if command -v apt >/dev/null 2>&1; then
    echo "[INFO] Ubuntu/Debian 환경: build deps 설치"
    sudo apt update -y
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev \
      libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev \
      wget curl libsqlite3-dev
  elif command -v yum >/dev/null 2>&1; then
    echo "[INFO] Rocky/CentOS 환경: build deps 설치"
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y gcc zlib-devel bzip2 bzip2-devel xz-devel wget make \
      libffi-devel sqlite sqlite-devel ncurses-devel gdbm-devel readline-devel tk-devel
  fi

  cd "$MY_PATH"
  wget "$PYTHON_SRC_URL" -O "Python-${PYTHON_VERSION}.tgz"
  tar -xzf "Python-${PYTHON_VERSION}.tgz"
  cd "Python-${PYTHON_VERSION}"

  ./configure --enable-optimizations --prefix=/usr/local
  make -j"$(nproc)"
  sudo make altinstall

  echo "✅ Python ${PYTHON_VERSION} 설치 완료"
  $PYTHON_BIN --version || true
}

#######################################################
#####           Function - pip.conf Setup          #####
#######################################################
configure_pip() {
  echo "========== pip.conf 설정 =========="

  local pip_conf="/etc/pip.conf"

  sudo tee "$pip_conf" > /dev/null <<EOF
[global]
index-url = ${PIP_INDEX_URL}
trusted-host = ${PIP_TRUST_HOST}
EOF

  echo "✅ pip.conf 설정 완료 → $pip_conf"
}

#######################################################
#####           Function - pip Install             #####
#######################################################
install_pip_packages() {
  echo "========== pip 패키지 설치 =========="

  # pip 설치 및 업그레이드
  $PYTHON_BIN -m ensurepip --upgrade || true
  $PYTHON_BIN -m pip install --upgrade pip setuptools wheel

  # 원하는 패키지 설치
  $PYTHON_BIN -m pip install $PIP_PACKAGES

  echo "✅ pip 패키지 설치 완료 ($PIP_PACKAGES)"
}

#######################################################
#####                     Main                     #####
#######################################################
main() {
  clone_repo
  build_python
  configure_pip
  install_pip_packages
}

main
