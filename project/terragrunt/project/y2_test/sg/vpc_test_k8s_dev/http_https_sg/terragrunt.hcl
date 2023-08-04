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
    source = "${get_parent_terragrunt_dir("root")}//modules/computing/sg"
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
    sg = {
        name = "${local.naming_rule_global}-ssh-rdp-sg"
        description = "For SSH/RDP"
        vpc_id = dependency.vpc_test_k8s_dev.outputs.vpc["id"]
        
            Name = "${local.naming_rule_global}-ssh-rdp-sg"
        }
    }

    ingress = {
        ssh_40022 = {
            from_port        = 40022
            to_port          = 40022
            protocol         = "tcp"
            cidr_blocks      = ["0.0.0.0/0"]
        }
        rdp_2073 = {
            from_port        = 2073
            to_port          = 2073
            protocol         = "tcp"
            cidr_blocks      = ["0.0.0.0/0"]
        }
    }

    egress = {
        all = {
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
        }
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