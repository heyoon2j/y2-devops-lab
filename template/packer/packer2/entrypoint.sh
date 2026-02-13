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
echo "▶️ Running Packer build for ${CLOUD} - ${OS_NAME}"
#packer build -var-file="${VARS}" "${TEMPLATE}"
packer build \
  -var-file="${VARS_DIR}/${OS_NAME}-${ARCH_TYPE}.pkrvars.hcl" \
  -var-file="${VARS_DIR}/common.pkrvars.hcl" \
  "${TEMPLATE_DIR}"