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

dependency "proto_vpc" {
    config_path = "${get_parent_terragrunt_dir("root")}//proto/dev/vpc"
}

dependency "secure_vpc" {
    config_path = "${get_parent_terragrunt_dir("root")}//network-proto/secure/prd/vpc"
}


###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/networking/tgw"
}

inputs = {
# Project Config
    proj_region = local.config_vars.locals.proj_region
    proj_name = local.config_vars.locals.proj_name
    proj_env = local.config_vars.locals.proj_env[2]

# TGW
    amazon_side_asn = 64512
    ## 연결된 교차 계정 연결을 자동으로 수락할지 여부
    auto_accept_shared_attachments = "disable"

    # TGW에 Default Routing Table 할당
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    # DNS Support
    dns_support = "enable"
    # VPN ECMP Routing
    vpn_ecmp_support = "enable"
    # Multicast Support
    multicast_support = "disable"

# Attachment

    attachment_vpc = [
        {
            name = "attachment-secure"
            vpc_name = dependency.secure_vpc.outputs.vpc["name"]
            vpc_id = dependency.secure_vpc.outputs.vpc["id"]
            subnet_ids = dependency.secure_vpc.outputs.attachment_subnet
        },
        {
            name = "attachment-proto"
            vpc_name =dependency.proto_vpc.outputs.vpc["name"]
            vpc_id = dependency.proto_vpc.outputs.vpc["id"]
            subnet_ids = dependency.proto_vpc.outputs.attachment_subnet
        }
    ]
    attachment_peering = []
    #attachment_vpn = []
    #attachment_dx = []

# Routing Table
    tgw_rt = [
        {
            name = "acl-route"
            associationList = ["attachment-secure"]
            propagationList = ["attachment-proto"]
            static_routes = [
                {
                    destination = "0.0.0.0/0"
                    attachment = "attachment-secure"             
                    blackhole = false                      
                }
            ]
        },
        {
            name = "app-route"
            associationList = ["attachment-acl"]
            propagationList = ["attachment-proto"]
            static_routes = [
                {
                    destination = "0.0.0.0/0"
                    attachment = "attachment-secure"                
                    blackhole = false                    
                }
            ]
        }/*,
        {
            name = ""
            associationList = ["attach-acl"]
            propagationList = ["attach-proto"]
            static_routes = [

            ]
        }*/
    ]


}








