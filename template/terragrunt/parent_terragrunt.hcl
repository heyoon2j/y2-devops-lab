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
    # CLI Options
    extra_arguments "tf_config" {
        commands = [
            "init",
            "plan",
            "apply",
            "refresh",
            "import",
            "taint",
            "untaint"
        ]
        env_vars = {
            TF_CLI_CONFIG_FILE = "${find_in_parent_folders("terraformrc.tfrc")}"
            TF_LOG_PATH = "/Users/heyoon2j/test.txt"
            TF_LOG = "debug"
        }
    }

    #######################################################
    # CLI Flag
    extra_arguments "env_vars" {
        commands = [
            "init",
            "plan",
            "apply",
            "refresh",
            "import",
            "taint",
            "untaint"
        ]
        env_vars = {
            ## CLI Config File
            TF_CLI_CONFIG_FILE = "${find_in_parent_folders("terraformrc.tfrc")}"

            ## Log Set
            TF_LOG_PATH = "$HOME/test.txt"
            TF_LOG = "info"
        }
    }


    extra_arguments "retry_lock" {
        commands  = get_terraform_commands_that_need_locking()
        arguments = ["-lock-timeout=20m"]
    }

    extra_arguments "parallelism" {
        commands  = get_terraform_commands_that_need_parallelism()
        arguments = ["-parallelism=5"]
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
            "${get_parent_terragrunt_dir()}/.tfvars"
            "${get_terragrunt_dir()}/terraform.tfvars"
        ]

        optional_var_files = [
            "${get_parent_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
            "${get_parent_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars",
            "${get_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
            "${get_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars"
        ]
    }

    // extra_arguments "debug" {
    //     commands = ["plan", "apply", "destroy"]
    //     arguments = ["--terragrunt-debug"]
    // }

    // extra_arguments "log_level" {
    //     commands = ["apply", "destroy"]
    //     arguments = ["--terragrunt-log-level info"]
    //     # panic / fatal / error / warn / info (this is the default) / debug / trace
    // }

    #######################################################
    # Hooking
    before_hook "before_hook_change" {
        commands     = ["apply"]
        execute      = ["echo", "########## Execute Terragrunt command for changing infra (Before Hook) ##########"]
        #run_on_error = true
    }

    after_hook "after_hook_change" {
        commands     = ["apply"]
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

