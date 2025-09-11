#!/bin/bash
set -e
CLOUD=$1
OS_NAME=$2
TEMPLATE="./${CLOUD}/build.pkr.hcl"
VARS="./${CLOUD}/variables/${OS_NAME}.pkrvars.hcl"
echo "▶️ Running Packer build for ${CLOUD} - ${OS_NAME}"
packer build -var-file="${VARS}" "${TEMPLATE}"
