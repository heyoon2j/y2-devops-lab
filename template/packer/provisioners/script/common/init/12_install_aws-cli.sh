#!/bin/bash

set -e

#######################################################
# Source common.sh
#######################################################
source /opt/packer/script/utils/common.sh

#######################################################
#####                Local Variable               #####
#######################################################
ARCH=$1

FILE_DIR="/opt/packer/files"

#######################################################
#####                  Function                   #####
#######################################################
apply_aws_cli() {
  echo "========== AWS CLI 설치 시작 =========="
    if command -v aws >/dev/null 2>&1; then
        echo "[OK] AWS CLI is already installed."
        return 0
    fi

    echo "[INFO] AWS CLI 설치 중..."
    if [[ "$ARCH" == "x86_64" ]]; then
        sudo cp "$FILE_DIR/aws-cli/awscli-exe-linux-x86_64.zip" /tmp/awscliv2.zip
    elif [[ "$ARCH" == "aarch64" ]]; then
        sudo cp "$FILE_DIR/aws-cli/awscli-exe-linux-aarch64.zip" /tmp/awscliv2.zip
    else
        echo "[ERROR] Unsupported architecture: $ARCH"
        return 1
    fi
    sudo unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin
    sudo rm -rf /tmp/aws /tmp/awscliv2.zip
    if command -v aws >/dev/null 2>&1; then
        aws --version
    else
        echo "[ERROR] AWS CLI install failed to put binary on PATH"
        return 1
    fi
    echo "[OK] AWS CLI 설치 완료"
}


main() {
  apply_aws_cli
}

main