#!/bin/bash
set -e
CLOUD=$1
OS_NAME=$2
ARCH_TYPE=$3
TEMPLATE_DIR="${CLOUD}"
VARS_DIR="${CLOUD}/variables"
echo "▶️ Running Packer build for ${CLOUD} - ${OS_NAME}"
#packer build -var-file="${VARS}" "${TEMPLATE}"
packer build \
  -var-file="${VARS_DIR}/${OS_NAME}-${ARCH_TYPE}.pkrvars.hcl" \
  -var-file="${VARS_DIR}/common.pkrvars.hcl" \
  "${TEMPLATE_DIR}"