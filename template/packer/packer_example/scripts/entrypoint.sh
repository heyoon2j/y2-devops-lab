#!/bin/bash
set -e
CLOUD=$1
OS=$2

AWS_PROFILE=packer-service-target
GCP_PROFILE=pakcer-service-target

packer build -var-file=variables/common.pkrvars.hcl -var="os_name=$OS" ${CLOUD}/template.pkr.hcl
