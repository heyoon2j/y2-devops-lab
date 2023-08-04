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


#####################################################
# 종속성
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

###############################################################
# Terraform Setting
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/networking/vpc"
}


###############################################################
# Variable
locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))
    vpc_cfg = read_terragrunt_config(find_in_parent_folders("vpc_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.test_k8s_dev["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.test_k8s_dev["naming_rule_global"]
}


inputs = {

# VPC
    vpc_name = "vpc-${local.naming_rule_global}"
    cidr_block = "172.16.30.0/23"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    enable_network_address_usage_metrics = false




    use_azs = ["ap-south-1a", "ap-south-1b"]


# subnet

    subnet_pub = {
        a_pub_lb = {
            name = "sbn-${local.naming_rule}-a-pub-lb"
            cidr_block = "172.16.30.0/26"
            availability_zone = "ap-south-1a"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = true         
        }
        b_pub_lb = {
            name = "sbn-${local.naming_rule}-b-pub-lb"
            cidr_block = "172.16.30.64/26"
            availability_zone = "ap-south-1b"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = true     
        }
    }

    subnet_pri = {
        a_pri_app = {
            name = "sbn-${local.naming_rule}-a-pri-app"
            cidr_block = "172.16.30.128/26"
            availability_zone = "ap-south-1a"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = false
        }
        b_pri_app = {
            name = "sbn-${local.naming_rule}-b-pri-app"
            cidr_block = "172.16.30.192/26"
            availability_zone = "ap-south-1b"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = false            
        }
        a_pri_db = {
            name = "sbn-${local.naming_rule}-a-pri-db"
            cidr_block = "172.16.31.0/26"
            availability_zone = "ap-south-1a"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = false
        }
        b_pri_db = {
            name = "sbn-${local.naming_rule}-b-pri-db"
            cidr_block = "172.16.31.64/26"
            availability_zone = "ap-south-1b"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = false
        }
        a_pri_gw = {
            name = "sbn-${local.naming_rule}-a-pri-gw"
            cidr_block = "172.16.31.128/26"
            availability_zone = "ap-south-1a"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = false
        }
        b_pri_gw = {
            name = "sbn-${local.naming_rule}-b-pri-gw"
            cidr_block = "172.16.31.192/26"
            availability_zone = "ap-south-1b"
            #private_dns_hostname_type_on_launch =  
            #ipv6_cidr_block = 
            assign_ipv6_address_on_creation = false
            map_public_ip_on_launch = false
        }
    }


# Routing Table
    rt_pub = {
        pub_lb = {
            name = "rt-${local.naming_rule}-pub-lb"
        }
    }
    rt_pub_assoc = {
        # subnet = routing table
        a_pub_lb = "pub_lb"
        b_pub_lb = "pub_lb"
    }

    rt_pri = {
        pri_app = {
            name = "rt-${local.naming_rule}-pri-app"
        }
        pri_db = {
            name = "rt-${local.naming_rule}-pri-db"
        }
        pri_gw = {
            name =  "rt-${local.naming_rule}-pri-gw"
        }
    }

    rt_pri_assoc = {
        a_pri_app = "pri_app"
        b_pri_app = "pri_app"
        a_pri_db = "pri_db"
        b_pri_db = "pri_db"
        a_pri_gw = "pri_gw"
        b_pri_gw = "pri_gw"
    }

# Internet Gateway
    internet_gateway = {
        name = "igw-${local.naming_rule}"
    }


# TGW Attachment Subnet
    tgw_attachment_subnet = ["sbn-${local.naming_rule}-a-pri-gw", "sbn-${local.naming_rule}-b-pri-gw"]

}
