###############################################################

include "root" {
    path = find_in_parent_folders()
    expose = false
}

include "remote_state" {
    path   = find_in_parent_folders("remote_state.hcl")
    expose = true
}

include "provider" {
    path   = find_in_parent_folders("provider.hcl")
    expose = true
}

locals {
    config_vars = read_terragrunt_config(find_in_parent_folders("config.hcl"))
    proj_region = local.config_vars.locals.proj_region
    proj_name = local.config_vars.locals.proj_name
    proj_env = local.config_vars.locals.proj_env[2]
}

###############################################################
# dependency
dependency "secure_vpc" {
    config_path = "${get_parent_terragrunt_dir("root")}//network-proto/secure/prd/vpc"
}

###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/storage/efs"
}

inputs = {
# efs
    efs = [
        {
            creation_token = "efs-${local.proj_name}-${local.proj_env}-test"

            subnet_id = dependency.secure_vpc.outputs.vpc["id"]
            # One Zone 인 경우만 해당!!
            availability_zone_name = null

            # Encyption
            encrypted = false
            kms_key_id = null

            # Class Type
            performance_mode = "generalPurpose"
            throughput_mode = "bursting"            # bursting, provisioned, elastic
            provisioned_throughput_in_mibps = null  # Only throughput_mode : Provisioned

            # Lifecycle
            lifecycle_transition_to_ia = null#"AFTER_90_DAYS"
            lifecycle_transition_to_primary_storage_class = "AFTER_1_ACCESS"

            # Backup
            use_autoBackup = "DISABLED"

            tags = {
                Name = "efs-${local.proj_name}-${local.proj_env}-test"
            }
        }
    ]

    efs_policy = [
        {
            name = "efs-${local.proj_name}-${local.proj_env}-test"
            policy = file("${get_parent_terragrunt_dir("root")}/policy/assumeRole_ec2.json")
        }
    ]

    efs_mount_target = [
        {
            efs_name = "efs-${local.proj_name}-${local.proj_env}-test"
            subnet_name = "sbn-secure-prd-as1-a-pub-untrust"
            ip_address = null
            security_groups = ["sg-0da809d721d44915f"]
        },
        {
            efs_name = "efs-${local.proj_name}-${local.proj_env}-test"
            subnet_name = "sbn-secure-prd-as1-b-pub-untrust"
            ip_address = null
            security_groups = ["sg-0da809d721d44915f"]
        }
    ]

}

###############################################################

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

inputs = {
    vpc_id = dependency.vpc.outputs.vpc_id
    db_url = dependency.rds.outputs.db_url
}
*/