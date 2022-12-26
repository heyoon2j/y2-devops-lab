
terraform {
    # source = "../modules/networking/vpc"
    source = "git::git@github.com:acme/infrastructure-modules.git//networking/vpc?ref=v0.0.1"

    #######################################################
    # CLI Flag
    extra_arguments "retry_lock" {
        commands  = get_terraform_commands_that_need_locking()
        arguments = ["-lock-timeout=20m"]
    }

    extra_arguments "custom_vars" {
        commands = [
            "apply",
            "plan",
            "import",
            "push",
            "refresh"
        ]

        required_var_files = [
            "${get_parent_terragrunt_dir()}/terraform.tfvars"
        ]

        optional_var_files = [
            "${get_parent_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
            "${get_parent_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars",
            "${get_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
            "${get_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars"
        ]
    }

    #######################################################
    # Hooking
    before_hook "before_hook_1" {
        commands     = ["apply", "plan"]
        execute      = ["echo", "########## Execute Terragrunt command for changing infra (Before Hook) ##########"]
        #run_on_error = true
    }

    after_hook "after_hook_1" {
        commands     = ["apply", "plan"]
        execute      = ["echo", "########## End Terragrunt command for changing infra (After Hook) ##########"]
        run_on_error = true
    }

    # after any error, with the ".*" expression.
    error_hook "error_hook_1" {
        commands  = ["apply", "plan"]
        execute   = ["echo", "########## Error Hook executed ##########"]
        on_errors = [
            ".*",
        ]
    }

    # A special after hook to always run after the init-from-module step of the Terragrunt pipeline. In this case, we will
    # copy the "foo.tf" file located by the parent terragrunt.hcl file to the current working directory.
    after_hook "init_from_module" {
        commands = ["init-from-module"]
        execute  = ["cp", "${get_parent_terragrunt_dir()}/foo.tf", "."]
    }

    # A special after_hook. Use this hook if you wish to run commands immediately after terragrunt finishes loading its
    # configurations. If "terragrunt-read-config" is defined as a before_hook, it will be ignored as this config would
    # not be loaded before the action is done.
    after_hook "terragrunt-read-config" {
        commands = ["terragrunt-read-config"]
        execute  = ["bash", "script/get_aws_credentials.sh"]
    }
}

generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite"
    contents = <<EOF
provider "aws" {
  region              = "us-east-1"
  version             = "= 2.3.1"
  allowed_account_ids = ["1234567890"]
}
EOF
}

generate "backend" {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
terraform {
    backend "s3" {
        bucket         = "my-terraform-state"
        key            = "${path_relative_to_include()}/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
        dynamodb_table = "my-lock-table"
    }
}
EOF
}

dependency "vpc" {
    config_path = "../vpc"
}

dependency "rds" {
    config_path = "../rds"
}

inputs = {
    vpc_id = dependency.vpc.outputs.vpc_id
    db_url = dependency.rds.outputs.db_url
}

dependencies {
    paths = ["../vpc", "../rds"]
}

include "remote_state" {
    path   = find_in_parent_folders()
    expose = true
}

include "region" {
    path           = find_in_parent_folders("region.hcl")
    expose         = true
    merge_strategy = "no_merge"
}

inputs = {
    remote_state_config = include.remote_state.remote_state
    region              = include.region.region
}