locals {
    user_data = file("${path.module}/../data/user_data/linux_init.sh")

    instances = {
        test_instance = {
            name            = "test_instance"
            instance_type   = "t2.small"
            image_name      = ""
            #key_name        = optional(string, null)

            # Network
            availability_zone           = "ap-northeast-2a"
            subnet_name                 = ""
            sg_names                    = [""]
            #source_dest_check           = optional(bool, true)
            ## Static or Dynamic IP
            #private_ip_static_enabled   = optional(bool, false)
            #private_ip_static_list      = optional(list(string), null)
            private_ip_dynamic          = 1
            ## Public IP
            #associate_public_ip_address = false
            ## Place Group
            #placement_group         = optional(string, null)
            #placement_partition_number = optional(string, null)

            root_volume                 = {
                #delete_on_termination       = optional(bool, true)
                #encrypted                   = optional(bool, false)
                #kms_key_id                  = optional(string, null)
                volume_type                 = "gp3"
                volume_size                 = 10
                #iops                        = optional(number, null)
                #throughput                  = optional(number, null)
            }

            add_volume                  = {
                name                        = "/dev/sdb"
                type                        = "gp3"
                size                        = 10
                #iops                        = optional(number, null)
                #throughput                  = optional(number, null)
            }



            # Option
            #tenancy                 = optional(string, "default")
            #disable_api_termination = optional(bool, true)
            #disable_api_stop        = optional(bool, false)
            #instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"
            #iam_instance_profile        = ""

            # Option - Neccessary
            ## Metadata
            #http_endpoint   = optional(string, "enabled")   # "enabled", "disabled"
            #http_tokens     = optional(string, "required")  # "required", "optional"
            #http_put_response_hop_limit = optional(number, 2)
            #instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
            ## 
            user_data                   = local.user_data
            tags                        = merge(
                local.common_config.default_tags,
                {
                    test = "test"
                }
            )
        }
    }
}