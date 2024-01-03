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
    source = "${get_parent_terragrunt_dir("root")}//data/routing/vpc_dmz_dr"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 종속성
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dependency "vpc" {
    config_path = "../../vpc/vpc_dmz_dr"
}

dependency "tgw" {
    config_path = "../../tgw"
}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.dmz_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.dmz_dr["naming_rule_global"]
}


inputs = {
# VPC
    vpc_id = dependency.vpc.outputs.vpc_id

# Subnet
    sbn_pub = dependency.vpc.outputs.sbn_pub
    sbn_pri = dependency.vpc.outputs.sbn_pri

# Route Table
    rt_pub = dependency.vpc.outputs.rt_pub
    rt_pri = dependency.vpc.outputs.rt_pri

# Other IDs
    gw_id = {
        igw = dependency.vpc.outputs.igw_id
        tgw = dependency.tgw.outputs.tgw_id
    }

    enpoint_id = {
        #nfw = 
    }
}
