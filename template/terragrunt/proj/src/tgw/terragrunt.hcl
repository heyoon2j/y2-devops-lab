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
    source = "${get_parent_terragrunt_dir("root")}//modules/networking/tgw"
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 종속성
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
dependency "vpc_acl_dr" {
    config_path = "../vpc/vpc_acl_dr"
}

dependency "vpc_dmz_dr" {
    config_path = "../vpc/vpc_dmz_dr"
}

dependency "vpc_shared_dr" {
    config_path = "../vpc/vpc_shared_dr"
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.acl_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.acl_dr["naming_rule_global"]
}


inputs = {
# Transti Gateway
    tgw_name = "tgw-dr"
    // amazon_side_asn = 64512
    // auto_accept_shared_attachments = disable
    // default_route_table_association = disable
    // default_route_table_propagation = disable
    // dns_support = enable
    // vpn_ecmp_support = enable
    // multicast_support = disable
    tags = {}

# Attachment
    attachment_vpc = {
        vpc_acl_dr = {
            name = "attach-acl-dr"
            vpc_id = dependency.vpc_acl_dr.outputs.vpc_id
            subnet_ids = dependency.vpc_acl_dr.outputs.tgw_attachment_subnet
            #tags = {}
        }
        vpc_dmz_dr = {
            name = "attach-dmz-dr"
            vpc_id = dependency.vpc_dmz_dr.outputs.vpc_id
            subnet_ids = dependency.vpc_dmz_dr.outputs.tgw_attachment_subnet
        }
        vpc_shared_dr = {
            name = "attach-shared-dr"
            vpc_id = dependency.vpc_shared_dr.outputs.vpc_id
            subnet_ids = dependency.vpc_shared_dr.outputs.tgw_attachment_subnet
        }
    }

     attachment_vpn = {}
     attachment_dx = {}
     attachment_peering = {}

# Route Table
    tgw_rt = {
        route_dr_acl = {
            name = "route-dr-acl"
            // tags = {}
        }
        route_dr_applications = {
            name = "route-dr-applications"
        }        
        route_dr_spoke-peering = {
            name = "route-dr-spoke-peering"
        }
    }
}
