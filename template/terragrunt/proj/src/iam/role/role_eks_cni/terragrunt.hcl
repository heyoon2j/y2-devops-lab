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
    source = "${get_parent_terragrunt_dir("root")}//modules/security/iam/role"
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
# Role
    name = "role-eks-vpccni-test"
    description = "Role managed by Terraform"
    path = "/"
    #max_ssession_duration = 1
    #force_detach_policies = false
    assume_role_policy = file("${get_parent_terragrunt_dir("root")}/data/policy/assumeRole_eks_vpccni.json")
    inline_policy = {
        test_1 = {
            name = "inline-test-1"
            policy = file("${get_parent_terragrunt_dir("root")}/data/policy/policy_kms.json")
        }
    }
    #permissions_boundary = "arn:..."
    tags = {
        managed_by = "Terraform"
    }

# Attachment
    policy_arn_custom = {}
    
    policy_arn_aws = {
        vpcCNiPolicy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    }
}