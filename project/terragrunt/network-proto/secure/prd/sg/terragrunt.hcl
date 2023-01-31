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
dependency "secure_vpc" {
    config_path = "${get_parent_terragrunt_dir("root")}//network-proto/secure/prd/vpc"
}

###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/computing/sg"
}

inputs = {
# Security Group
    sg = [
        {
            name = "${local.proj_name}-${local.proj_env}-http-sg"
            description = "For HTTP/HTTPS"
            vpc_id = dependency.secure_vpc.outputs.vpc["id"]
        },
        {
            name = "${local.proj_name}-${local.proj_env}-ssh-rdp-sg"
            description = "For SSH and RDP"
            vpc_id = dependency.secure_vpc.outputs.vpc["id"]
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