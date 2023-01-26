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
    source = "${get_parent_terragrunt_dir("root")}/modules/networking/tgw"

    after_hook "after_hook_run_python" {
        commands     = ["apply", "plan"]
        execute      = ["echo", "########## End Terragrunt command for changing infra (After Hook) ##########"]
        run_on_error = true
    }

    # after any error, with the ".*" expression.
    error_hook "error_hook" {
        commands  = ["apply", "plan"]
        execute   = ["echo", "########## Error Hook executed ##########"]
        on_errors = [
            ".*",
        ]
    }
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
    attachment_vpc = ["attach-acl","attach-proto"]
    attachment_tgw = []
    attachment_vpn = []
    attachment_dx = []

# Routing Table
    tgw_rt = [
        {
            name = "acl-route"
            associationList = ["attach-acl"]
            propagationList = ["attach-proto"]
            static_routes = [
                {
                    destination = "0.0.0.0/0"
                    target = ""                
                    blackhole = false                      
                }
            ]
        },
        {
            name = "app-route"
            associationList = ["attach-acl"]
            propagationList = ["attach-proto"]
            static_routes = [
                {
                    destination = "0.0.0.0/0"
                    target = ""                
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








