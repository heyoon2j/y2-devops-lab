#!/bin/bash

set -e

#######################################################
#####                Local Variable               #####
#######################################################
GITHUB_URL="https://github.test.com/abc-test/aa.git"
BRANCH_NAME="dev-test"
GITHUB_USER="your-username"           # 여기에 사용자명 입력
GITHUB_TOKEN="your-personal-access-token"  # 여기에 PAT 입력
MY_PATH="/opt/"

#######################################################
#####               Function - Main               #####
#######################################################
main() {
  echo "========== Monitoring Setting Start =========="

  cd "$MY_PATH"
  # PAT 인증을 URL에 포함 (보안상 비추천, 테스트용)
  AUTH_URL=$(echo "$GITHUB_URL" | sed "s#https://#https://$GITHUB_USER:$GITHUB_TOKEN@#")
  git clone --branch "$BRANCH_NAME" "$AUTH_URL"
}

#######################################################
#####                                             #####
#######################################################
main