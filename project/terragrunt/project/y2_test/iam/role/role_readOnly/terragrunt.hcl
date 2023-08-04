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


###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/security/iam/role"
}


###############################################################
# Variable
locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.test_k8s_dev["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.test_k8s_dev["naming_rule_global"]
}



inputs = {
# Role
    role = {
        name = "role-${local.naming_rule_global}-readOnly"
        assume_role_policy = file("${get_parent_terragrunt_dir("root")}/data/policy/assumeRole_ec2.json")
        inline_policy = {
            inline-policy-ec2-readOnly = {
                name = "inline-policy-ec2-readOnly"
                policy = file("${get_parent_terragrunt_dir("root")}/data/policy/policy_ec2_readOnly.json")
            }
        }

        #managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]

        permissions_boundary = "arn:aws:iam::${get_aws_account_id()}:policy/policy-bdy-${local.naming_rule_global}-manager"
        tags = {}
    }


# Attachment
    attach_policy_custom = {
        ec2-readOnly = "arn:aws:iam::${get_aws_account_id()}:policy/policy-${local.naming_rule_global}-ec2-readOnly"
    }
    
    attach_policy_aws = {
        readOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
}