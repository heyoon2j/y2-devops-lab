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
    source = "${get_parent_terragrunt_dir("root")}//modules/security/nfw"
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 종속성
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dependency "vpc" {
    config_path = "../../vpc/vpc_acl_dr"
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
# Firewall
    firewall = {
        name = "nfw-${local.naming_rule_global}"
        description = "Network Firewall"
        vpc_id = dependency.vpc.outputs.vpc_id
        subnet_mapping = {
            subnet1 = {
                subnet_id = dependency.vpc.outputs.sbn_pri["d_pri_trust"]
                #ip_address_type = "DUALSTACK"
            }
        }
        subnet_change_protection = true
        #encryption_configuration = {}
        firewall_policy_change_protection = true
        delete_protection = false
        logging_configuration = null
        tags = null
    }

# Firewall Policy
    firewall_policy = {
        name = "nfw-policy-${local.naming_rule_global}-default" 
        description = "Network Firewall Policy" 
        #encryption_configuration = {}
        // policy_variables = {
        //     home_net = {
        //         key = "HOME_NET"
        //         ip_set = ["10.0.0.0/16", "10.1.0.0/24"]
        //     }
        // }
        stateless_default_actions = ["aws:forward_to_sfe"]
        stateless_fragment_default_actions = ["aws:forward_to_sfe"]
        stateless_rule_group_reference = {}
        stateful_engine_options = {
            rule_order = "STRICT_ORDER"     # "DEFAULT_ACTION_ORDER", "STRICT_ORDER"
            #stream_exception_policy = "DROP"
        }
        stateful_default_actions = ["aws:drop_strict", "aws:alert_strict"]
        stateful_rule_group_reference = {}
        tags = {}        
    }

# Firewall Logging
    // log_destination_type = "CloudWatchLogs"
    // firewall_logging = {
    //     flow = {
    //         log_destination = {
    //             logGroup = "/nfw-${local.naming_rule_global}/flow"
    //         }
    //         log_type = "FLOW"
    //     }
    //     alert = {
    //         log_destination = {
    //             logGroup = "/nfw-${local.naming_rule_global}/alert"
    //         }
    //         log_type = "ALERT"
    //     }
    // }
}
