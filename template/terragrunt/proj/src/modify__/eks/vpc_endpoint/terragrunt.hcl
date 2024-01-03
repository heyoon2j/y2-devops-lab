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
    source = "${get_parent_terragrunt_dir("root")}//modules/networking/endpoint"
}


###############################################################
# Variable
locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.acl_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.acl_dr["naming_rule_global"]

    vpc_id = "vpc-0785d8a8481fec2c9"
    subnet_ids = ["subnet-07ee2a6186b14ab09", "subnet-06017c3f803e73c75"]
    security_group_ids = ["sg-004a4cd3771dcff68"]

}


inputs = {
    endpoint = {
        lb = {
            service_name = "com.amazonaws.ap-south-1.elasticloadbalancing"
            vpc_endpoint_type = "Interface"

            vpc_id       = local.vpc_id
            subnet_ids   = local.subnet_ids
            security_group_ids = local.security_group_ids
            route_table_ids = []

            tags = {
                Name = "endpoint-lb"
            }
        }
        sts = {
            service_name = "com.amazonaws.ap-south-1.sts"
            vpc_endpoint_type = "Interface"

            vpc_id       = local.vpc_id
            subnet_ids   = local.subnet_ids
            security_group_ids = local.security_group_ids
            route_table_ids = []

            tags = {
                Name = "endpoint-sts"
            }
        }
        ecr_api = {
            service_name = "com.amazonaws.ap-south-1.ecr.api"
            vpc_endpoint_type = "Interface"

            vpc_id       = local.vpc_id
            subnet_ids   = local.subnet_ids
            security_group_ids = local.security_group_ids
            route_table_ids = []

            tags = {
                Name = "endpoint-ecr-api"
            }
        }
        ecr_dkr = { 
            service_name = "com.amazonaws.ap-south-1.ecr.dkr"
            vpc_endpoint_type = "Interface"

            vpc_id       = local.vpc_id
            subnet_ids   = local.subnet_ids
            security_group_ids = local.security_group_ids
            route_table_ids = []

            tags = {
                Name = "endpoint-ecr-dkr"
            }
        }
        logs = { 
            service_name = "com.amazonaws.ap-south-1.logs"
            vpc_endpoint_type = "Interface"

            vpc_id       = local.vpc_id
            subnet_ids   = local.subnet_ids
            security_group_ids = local.security_group_ids
            route_table_ids = []

            tags = {
                Name = "endpoint-logs"
            }
        }
        s3 = {
            service_name = "com.amazonaws.ap-south-1.s3"
            vpc_endpoint_type = "Interface"

            vpc_id       = local.vpc_id
            subnet_ids   = local.subnet_ids
            security_group_ids = local.security_group_ids
            route_table_ids = []

            tags = {
                Name = "endpoint-s3"
                test = "false"
            }
        }
    }

}
