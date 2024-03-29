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
    source = "${get_parent_terragrunt_dir("root")}//modules/security/iam/policy"
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 종속성
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.acl_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.acl_dr["naming_rule_global"]
}

inputs = {
# Policy
    policy_custom = {
        policy_ec2_readOnly = {
            name = "policy-${local.naming_rule_global}-ec2-readOnly-test"
            description = "Ec2 Read Only Document"
            path = "/"
            policy = file("${get_parent_terragrunt_dir("root")}/data/policy/policy_ec2_readOnly.json")
        },
        policy_kms = {
            name = "policy-${local.naming_rule_global}-kms-test"
            description = "Using KMS"
            path = "/"
            policy = file("${get_parent_terragrunt_dir("root")}/data/policy/policy_kms.json")            
        }
    }

    policy_boundary = {
        policy_bdy_manager = {
            name = "policy-bdy-${local.naming_rule_global}-manager-test"
            description = "Manager Group's Policy Boundary"
            path = "/"
            policy = file("${get_parent_terragrunt_dir("root")}/data/policy/policy_ec2_readOnly.json")
        }        
    }

}