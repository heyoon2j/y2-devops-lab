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

    naming_rule = local.proj_cfg.locals.shared_dr["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.shared_dr["naming_rule_global"]
}


inputs = {
    available_zons = ["ap-northeast-2c", "ap-northeast-2d"]

# VPC
    vpc_name = "vpc-${local.naming_rule_global}"
    cidr_block = "10.251.4.0/23"
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
        d_pri_elb = {
            name = "d-pri-elb"
            cidr_block = "10.251.4.0/26"
            #ipv6_cidr_block = 
            availability_zone = "ap-northeast-2d"
            route_table = "pri_elb"
            #tags = {}
        }

        c_pri_elb = {
            name = "c-pri-elb"
            cidr_block = "10.251.4.64/26"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_elb"
        }

        d_pri_app = {
            name = "d-pri-app"
            cidr_block = "10.251.4.128/25"
            availability_zone = "ap-northeast-2d"
            route_table = "pri_app"
        }

        c_pri_app = {
            name = "c-pri-app"
            cidr_block = "10.251.5.0/25"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_app"
        }

        d_pri_db = {
            name = "d-pri-db"
            cidr_block = "10.251.5.128/26"
            availability_zone = "ap-northeast-2d"
            route_table = "pri_db"
        }

        c_pri_db = {
            name = "c-pri-db"
            cidr_block = "10.251.5.192/26"
            availability_zone = "ap-northeast-2c"
            route_table = "pri_db"
        }
    }


# TGW Attachment Subnet
    tgw_attachment_subnet = ["d-pri-elb"]


# Routing Table
    rt_common_config = {
        naming_rule = "rt-${local.naming_rule}-"
        tags = {
            Manage_by = "Terraform"
        }
    }
    rt_pub = {}

    rt_pri = {
        pri_elb = {
            name = "pri-elb"
            #tags = {}
        }
        pri_app = {
            name =  "pri-app"
        }
        pri_db = {
            name =  "pri-db"
        }     
    }
}