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
    source = "${get_parent_terragrunt_dir("root")}//modules/networking/vpc"

    // after_hook "after_hook_update_route" {
    //     commands     = ["apply"]
    //     execute      = ["terragrunt apply", "########## End Terragrunt command for changing infra (After Hook) ##########"]
    //     run_on_error = false
    // }
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 종속성
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))
    vpc_cfg = read_terragrunt_config(find_in_parent_folders("vpc_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.acl_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.acl_dr["naming_rule_global"]
}


inputs = {
    available_zons = ["ap-northeast-2c", "ap-northeast-2d"]

# VPC
    vpc_name = "vpc-${local.naming_rule_global}"
    cidr_block = "10.251.0.0/23"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    enable_network_address_usage_metrics = false
    tags = {
        Manage_by = "Terraform"
    }


# subnet
    sbn_common_config = {
        naming_rule = "sbn-${local.naming_rule}-"
        assign_ipv6_address_on_creation = false
        map_public_ip_on_launch = false
        #private_dns_hostname_type_on_launch =  
        tags = {
            Manage_by = "Terraform"
        }
    }
    
    sbn_pub = {
    }

    sbn_pri = {
        d_pri_mgmt = {
            name = "d-pri-mgmt"
            cidr_block = "10.251.0.0/28"
            #ipv6_cidr_block =             
            availability_zone = "ap-northeast-2d"
            route_table = "pri_mgmt"
            #tags = {}
        }

        c_pri_mgmt = {
            name = "c-pri-mgmt"
            cidr_block = "10.251.0.16/28"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_mgmt"
        }

        d_pri_ha = {
            name = "d-pri-ha"
            cidr_block = "10.251.0.32/28"
            availability_zone = "ap-northeast-2d"
            route_table = "pri_ha"
        }

        c_pri_ha = {
            name = "c-pri-ha"
            cidr_block = "10.251.0.48/28"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_ha"
        }

        d_pri_untrust = {
            name = "d-pri-untrust"
            cidr_block = "10.251.0.64/28"
            availability_zone = "ap-northeast-2d"
            route_table = "pri_untrust"
        }

        c_pri_untrust = {
            name = "c-pri-untrust"
            cidr_block = "10.251.0.80/28"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_untrust"
        }

        d_pri_trust = {
            name = "d-pri-trust"
            cidr_block = "10.251.0.96/28"
            availability_zone = "ap-northeast-2d"
            route_table = "pri_trust"
        }

        c_pri_trust = {
            name = "c-pri-trust"
            cidr_block = "10.251.0.112/28"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_trust"
        }

        d_pri_dummy = {
            name = "d-pri-dummy"
            cidr_block = "10.251.0.128/28"
            availability_zone = "ap-northeast-2d"
            route_table = "pri_dummy"
        }

        c_pri_dummy = {
            name = "c-pri-dummy"
            cidr_block = "10.251.0.144/28"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_dummy"
        }
    }


# TGW Attachment Subnet
    tgw_attachment_subnet = ["d-pri-dummy"]


# Routing Table
    rt_common_config = {
        naming_rule = "rt-${local.naming_rule}-"
        tags = {
            Manage_by = "Terraform"
        }
    }

    rt_pub = {}

    rt_pri = {
        pri_mgmt = {
            name = "pri-mgmt"
            #tags = {}
        }
        pri_ha = {
            name =  "pri-ha"
        }
        pri_untrust = {
            name = "pri-untrust"
        }
        pri_trust = {
            name =  "pri-trust"
        }
        pri_dummy = {
            name = "pri-dummy"
        }        
    }

    // igw_name = "igw-${local.naming_rule}"
    // igw_tags = {}
}
