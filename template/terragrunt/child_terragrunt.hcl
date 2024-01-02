#############################################################################################
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
#############################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 구성 상속
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Terraform Setting
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

terraform {
    # source = "../modules/networking/vpc"
    source = "git::git@github.com:acme/infrastructure-modules.git//networking/vpc?ref=v0.0.1"

    #######################################################
    # CLI Flag
    extra_arguments "retry_lock" {
        commands  = get_terraform_commands_that_need_locking()
        arguments = ["-lock-timeout=20m"]
    }

    extra_arguments "custom_vars" {
        commands = [
            "apply",
            "plan",
            "import",
            "push",
            "refresh"
        ]

        required_var_files = [
            "${get_parent_terragrunt_dir()}/terraform.tfvars"
        ]

        optional_var_files = [
            "${get_parent_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
            "${get_parent_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars",
            "${get_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
            "${get_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars"
        ]
    }

    #######################################################
    # Hooking
    before_hook "before_hook_1" {
        commands     = ["apply", "plan"]
        execute      = ["echo", "########## Execute Terragrunt command for changing infra (Before Hook) ##########"]
        #run_on_error = true
    }

    after_hook "after_hook_1" {
        commands     = ["apply", "plan"]
        execute      = ["echo", "########## End Terragrunt command for changing infra (After Hook) ##########"]
        run_on_error = true
    }

    # after any error, with the ".*" expression.
    error_hook "error_hook_1" {
        commands  = ["apply", "plan"]
        execute   = ["echo", "########## Error Hook executed ##########"]
        on_errors = [
            ".*",
        ]
    }

    # A special after hook to always run after the init-from-module step of the Terragrunt pipeline. In this case, we will
    # copy the "foo.tf" file located by the parent terragrunt.hcl file to the current working directory.
    after_hook "init_from_module" {
        commands = ["init-from-module"]
        execute  = ["cp", "${get_parent_terragrunt_dir()}/foo.tf", "."]
    }

    # A special after_hook. Use this hook if you wish to run commands immediately after terragrunt finishes loading its
    # configurations. If "terragrunt-read-config" is defined as a before_hook, it will be ignored as this config would
    # not be loaded before the action is done.
    after_hook "terragrunt-read-config" {
        commands = ["terragrunt-read-config"]
        execute  = ["bash", "script/get_aws_credentials.sh"]
    }
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 종속성
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dependency "vpc" {
    config_path = "../vpc"
}

dependency "rds" {
    config_path = "../rds"
}

dependencies {
    paths = ["../vpc", "../rds"]
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))
    vpc_cfg = read_terragrunt_config(find_in_parent_folders("vpc_cfg.hcl"))
}


inputs = {
    naming_rule = local.proj_cfg.test_k8s_dev["naming_rule"]
    naming_rule_global = local.proj_cfg.test_k8s_dev["naming_rule_global"]


# VPC
    cidr_block="172.16.30.0/24"
    #ipv6_cidr_block = ""
    instance_tenancy="default"
    enable_dns_support=true
    enable_dns_hostnames=true

    available_zons = ["ap-northeast-2c", "ap-northeast-2d"]
}