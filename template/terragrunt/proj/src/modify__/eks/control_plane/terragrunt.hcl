/*
Child Config
- 상속 받을 내용
- Module을 위한 내용

1. 상속 받을 내용
    - Provider 설정 (include)
    - Backend 설정 (include)
    - 모든 Command에 대한 옵션 값 지정 (include)
    - 모든 Command에 대한 Hooking (include)
2. Module을 위한 내용
    - Module 종속성 지정
    - Module Source 위치 
    - Input 값 입력 or Variables 파일 지정
    - 해당 Module에 해당하는 Command에 대한 옵션 값 지정 (Option)
    - 해당 Module에 해당하는 Command에 대한 Hooking (Option)
*/

#####################################################
# 구성 상속
include "root" {
    path   = find_in_parent_folders()
    expose = true 
}

include "provider" {
    path   = find_in_parent_folders("provider.hcl")
    expose = true 
}

include "remote_state" {
    path   = find_in_parent_folders("remote_state.hcl")
    expose = true
}


#####################################################
# 종속성
/*
dependency "vpc" {
    config_path = "../vpc"
}

dependency "rds" {
    config_path = "../rds"
}

dependencies {
    paths = ["../vpc", "../rds"]
}
*/


###############################################################
# Terraform Setting
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/container/control_plane"
}


###############################################################
# Variable
locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.acl_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.acl_dr["naming_rule_global"]
}


inputs = {
    control_plane = {
        name = "eks-${local.naming_rule_global}"                   # Control Plane's Name
        #version = ""                # Control Plane's Version
        role_arn = "arn:aws:iam::704205518560:role/role-test-k8s-dev-eks"               # Control Plane's Role
        
        # VPC Network Config (== Physical)
        vpc_config = {
            subnet_ids = ["subnet-0bd2a51071c8252bf", "subnet-019edf5a017be9a9d"]
            security_group_ids = ["sg-004a4cd3771dcff68"]
            endpoint_private_access = true
            endpoint_public_access  = false
            public_access_cidrs = null
        }

        # Kubernetes Network Config (== Logical)
        kubernetes_network_config = {
            ip_family = "ipv4"
            service_ipv4_cidr = "10.100.0.0/16"
        }

        # Encryption for Secrets object
        encryption_config = {
            key_arn = "arn:aws:kms:ap-south-1:704205518560:key/cf963348-7959-414f-a76e-9a3af541d88e"
            resources = ["secrets"]
        }

        enabled_cluster_log_types = []
        tags = {}
    }
}
