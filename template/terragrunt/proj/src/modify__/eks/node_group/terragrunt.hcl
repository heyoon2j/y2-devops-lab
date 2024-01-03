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
    source = "${get_parent_terragrunt_dir("root")}//modules/container/node_group"
}


###############################################################
# Variable
locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.acl_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.acl_dr["naming_rule_global"]
}


inputs = {

    compute_machines = {
        cluster_name    = "eks-acl-dr"

        # Node Group Configuration
        node_group_name = "eks-ng-acl-dr"
        node_role_arn   = "arn:aws:iam::704205518560:role/role-test-k8s-dev-eks-node"
        labels          = {}
        taint           = {
            test = {
                key = "testKey"
                value = "testValue"
                effect = "PREFER_NO_SCHEDULE"
            }
        }

        # Network
        subnet_ids      = ["subnet-0bd2a51071c8252bf", "subnet-019edf5a017be9a9d"]
       
        # EC2 Resource Spec
        launch_template = {
            // id = optional(string)
            name = "test-eks-lt"
            version = 1
        }
            # ami_type - (Optional) Type of Amazon Machine Image (AMI) associated with the EKS Node Group. See the AWS documentation for valid values. Terraform will only perform drift detection if a configuration value is provided.
            # release_version – (Optional) AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version.
            # instance_types - (Optional) List of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided.
            # capacity_type - (Optional) Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided.
            # disk_size - (Optional) Disk size in GiB for worker nodes. Defaults to 50 for Windows, 20 all other node groups. Terraform will only perform drift detection if a configuration value is provided.
        scaling_config  = {
            desired_size = 1
            max_size     = 1
            min_size     = 1
        }

        remote_access = {
            // ec2_ssh_key = optional(string)
            // source_security_group_ids = optional(list(string))
        }

        # 업데이트 사용 불가 가능 갯수
        update_config   = {
            // max_unavailable = optional(number)
            max_unavailable_percentage = 50
        }

        tags = {}
    }

}
