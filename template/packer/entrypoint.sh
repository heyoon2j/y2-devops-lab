#!/bin/bash
set -e

## CLOUD: aws / gcp / kc
## OS_NAME: ubuntu20 / ubuntu22 / rocky8 / rocky9 / amazon2 / amazon2023
## ARCH_TYPE: x86_64 / arm64
## Usage: entrypoint.sh <CLOUD> <OS_NAME> <ARCH_TYPE>
CLOUD=$1
OS_NAME=$2
ARCH_TYPE=$3
TEMPLATE_DIR="${CLOUD}"
VARS_DIR="${CLOUD}/variables"

# 로그 파일명변 변수에 저장 (S3 업로드용)
LOG_FILE="packer_${CLOUD}_${OS_NAME}_${ARCH_TYPE}_$(date +%Y%m%d_%H%M%S).log"
S3_BUCKET="dev-cloud-image-logs"
S3_PATH="packer/${CLOUD}/${OS_NAME}/${ARCH_TYPE}/${LOG_FILE}"

echo "▶️ Running Packer build for ${CLOUD} - ${OS_NAME}"
echo "Log file: ${LOG_FILE}"

# Pakcer build 실행 및 로그 저장
nohup packer build \
  -var-file="${VARS_DIR}/${OS_NAME}-${ARCH_TYPE}.pkrvars.hcl" \
  -var-file="${VARS_DIR}/common.pkrvars.hcl" \
  -var "ssh_username=packer" \
  -var "ssh_password=packer12!@" \
  -var "log_file_name=${LOG_FILE}" \
  -var "s3_bucket=${S3_BUCKET}" \
  -var "s3_path=${S3_PATH}" \
  "${TEMPLATE_DIR}" 2>&1 | tee -a "${LOG_FILE}" &

BUILD_STATUS=$?

if [ ${BUILD_STATUS} -eq 0 ]; then
  echo "Packer build completed successfully."
else
  echo "Packer build failed with status: ${BUILD_STATUS}"
  exit ${BUILD_STATUS}
fi