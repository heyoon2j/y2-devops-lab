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
    proj_region = local.config_vars.locals.proj_region
    proj_name = local.config_vars.locals.proj_name
    proj_env = local.config_vars.locals.proj_env[2]
}


###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/security/iam"
}

inputs = {
    #remote_state_config = include.remote_state.remote_state
    #region              = include.region.region
    // proj_region = local.config_vars.locals.proj_region
    // proj_name = local.config_vars.locals.proj_name
    // proj_env = local.config_vars.locals.proj_env[2]


# Role
    role = [
        {
            name = "role-${local.proj_name}-${local.proj_env}-ec2-readOnly"
            assume_role_policy = file("${get_parent_terragrunt_dir("root")}/policy/assumeRole_ec2.json")
            // "{
            //     Version = \"2012-10-17\"
            //     Statement = [
            //         {
            //             Sid    = \"test\"
            //             Action = \"sts:AssumeRole\"
            //             Effect = \"Allow\"
            //             Principal = {
            //                 Service = \"ec2.amazonaws.com\"
            //             }
            //         }
            //     ]
            // }"
        }
    ]

    user_policy = [
        /*
        {
            name = "",
            path = "/",
            description = "s3-"
            json = file("${get_parent_terragrunt_dir("root")}/policy/assumeRole_ec2.json")
            attachment_roles = []
            attachment_users = []
            attachment_groups = []            
        }
        */
    ]

    aws_policy = [
        {
            name = "readOnlyAccess-attachment"
            arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
            attachment_roles = ["role-${local.proj_name}-${local.proj_env}-ec2-readOnly"]
            attachment_users = []
            attachment_groups = []
        }
    ]

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