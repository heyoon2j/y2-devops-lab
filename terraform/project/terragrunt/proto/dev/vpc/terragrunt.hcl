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
}


###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}/modules/networking/vpc"
}

inputs = {
    #remote_state_config = include.remote_state.remote_state
    #region              = include.region.region
    proj_region = local.config_vars.locals.proj_region
    proj_name = local.config_vars.locals.proj_name
    proj_env = local.config_vars.locals.proj_env[0]


# VPC
    cidr_block="172.16.30.0/24"
    #ipv6_cidr_block = ""
    instance_tenancy="default"
    enable_dns_support=true
    enable_dns_hostnames=true

# subnet
    pub_subnet = {
        subnet_name = ["a-pub-lb", "b-pub-lb"]
        cidr_block = ["172.16.30.0/27", "172.16.30.32/27"]
        availability_zone = ["ap-south-1a", "ap-south-1b"] #1b"]
        #private_dns_hostname_type_on_launch =  
        #ipv6_cidr_block =
        assign_ipv6_address_on_creation = false
        map_public_ip_on_launch = true
    }

    pri_subnet = {
        subnet_name = ["a-pri-lb", "b-pri-lb"]
        cidr_block = ["172.16.30.64/27", "172.16.30.96/27"]
        availability_zone = ["ap-south-1a", "ap-south-1b"] #1b"]
        #private_dns_hostname_type_on_launch =  
        #ipv6_cidr_block =
        assign_ipv6_address_on_creation = false
        map_public_ip_on_launch = false
    }
/*
    pub_subnet_name = ["sbn-proto-pub1", "sbn-proto-pub2"]
    pub_cidr_block = ["172.16.30.0/27", "172.16.30.32/27"]
    pub_availability_zone = ["ap-south-1a", "ap-south-1b"] #1b"]
    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    pub_assign_ipv6_address_on_creation = false
    pub_map_public_ip_on_launch = false
*/

# Routing Table
    pub_rt = [
        {
            rt_name = "pri-untrust"   
            route = null
        }
    ]
    /*
        {
            rt_name = "pri-mgmt"   
            route = []
        },
        {
            rt_name = "pri-db"
            route = []
        } 
    */
    pri_rt = null
    /*[
        {
            rt_name = "pri-lb"   
            route = []
        },
        {
            rt_name = "pri-app"   
            route = []
        },
        {
            rt_name = "pri-db"
            route = []
        }
    ]*/

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