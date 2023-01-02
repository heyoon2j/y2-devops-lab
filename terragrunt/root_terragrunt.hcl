/*
Root Config
- 상속 시킬 내용

1. 상속 시킬 내용
    - Provider 설정
    - Backend 설정
    - 모든 Command에 대한 옵션 값 지정
    - 모든 Command에 대한 Hooking

*/


terraform {
    #######################################################
    # CLI Flag
    extra_arguments "retry_lock" {
        commands  = get_terraform_commands_that_need_locking()
        arguments = ["-lock-timeout=20m"]
    }

    extra_arguments "parallelism" {
        commands  = get_terraform_commands_that_need_parallelism()
        arguments = ["-parallelism=5"]
    }


    #######################################################
    # Hooking
    before_hook "before_hook_change" {
        commands     = ["apply", "plan"]
        execute      = ["echo", "########## Execute Terragrunt command for changing infra (Before Hook) ##########"]
        #run_on_error = true
    }

    after_hook "after_hook_change" {
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
