###############################################################

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

###############################################################
dependency "vpc_test_k8s_dev" {
    config_path = "${get_parent_terragrunt_dir("root")}//project/y2_test/vpc/vpc_test_k8s_dev"
}


###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/computing/launch_template"
}


###############################################################
# Variable
locals {
    proj_cfg = read_terragrunt_config(find_in_parent_folders("proj_cfg.hcl"))

    naming_rule = local.proj_cfg.locals.test_k8s_dev["naming_rule"]
    naming_rule_global = local.proj_cfg.locals.test_k8s_dev["naming_rule_global"]
}



inputs = {
# Security Group
    launch_temp = {
        template_name = "default-template-public"
        image_id = "ami-021f7978361c18b01"
        
        # CPU & Memory
        instance_type = null #(Set value when execute instance)

        key_name = null

        # Network
        associate_public_ip_address = true
        vpc_security_group_ids = null
        
        block_device_mappings = {
            vol_root = {
                device_name = "/dev/xvda"
                volume_size = 10
                volume_type = "gp3"
                iops = 3000
                throughput = 125

                delete_on_termination = true
                encrypted = true
                kms_key_id = null
            }
        }
        
        iam_instance_profile = {
            # name = name
        }

        private_dns_name_options = {
            hostname_type = "ip-name"
            enable_resource_name_dns_a_record = true
        }

        instance_initiated_shutdown_behavior = "stop"

        hibernation_options = {
            configured = false
        }

        disable_api_stop = false
        disable_api_termination = false

        monitoring = {
            enabled = false
        }

        ebs_optimized = true

        metadata_options = {
            http_endpoint               = "enabled"
            http_tokens                 = "required"
            http_put_response_hop_limit = 1
            instance_metadata_tags      = "enabled"
        }

        user_data = filebase64("${get_parent_terragrunt_dir("root")}/data/user_data/linux_init.sh")
        tag_specifications = {}
    }
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