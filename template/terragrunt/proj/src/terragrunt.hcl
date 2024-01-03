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
    extra_arguments "retry_lock" {
        commands  = get_terraform_commands_that_need_locking()
        arguments = ["-lock-timeout=20m"]
    }

    extra_arguments "parallelism" {
        commands  = get_terraform_commands_that_need_parallelism()
        arguments = ["-parallelism=5"]
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
}

