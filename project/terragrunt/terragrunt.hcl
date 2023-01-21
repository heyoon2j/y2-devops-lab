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
}