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
# dependency

###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/storage/s3"
}

inputs = {
# S3
    s3 = [
        {
            name = "s3-${local.proj_name}-${local.proj_env}-test"
            tags = {
                Name = "s3-${local.proj_name}-${local.proj_env}-test"
                env = "test"
            }
            block_public_acls       = true
            ignore_public_acls      = true
            block_public_policy     = true
            restrict_public_buckets = true

            object_ownership = "BucketOwnerEnforced" #BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced

            bucket_key_enabled = true
            sse_algorithm = "aws:kms"        # AES256 / aws:kms
            kms_id = "aws/s3"                   # aws/s3 / arn:
        }
    ]

    s3_bucket_policy = [
        /*
        {
            name = "s3-${local.proj_name}-${local.proj_env}-test"
            bucket_policy = file("${get_parent_terragrunt_dir("root")}/policy/assumeRole_ec2.json")
        }
        */
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