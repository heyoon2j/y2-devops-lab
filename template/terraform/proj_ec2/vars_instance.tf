locals {
    user_data = ""

    instances = {
        test_instance = {
            name            = "test_instance"
            instance_type   = "t2.small"
            image_name      = ""
            #key_name        = optional(string, null)

            # Network
            subnet_name                 = ""
            sg_names                    = [""]
            #source_dest_check           = optional(bool, true)
            ## Static or Dynamic IP
            #private_ip_static_enabled   = optional(bool, false)
            #private_ip_static_list      = optional(list(string), null)
            private_ip_dynamic          = 1
            ## Public IP
            associate_public_ip_address = false
            ## Place Group
            #placement_group         = optional(string, null)
            #placement_partition_number = optional(string, null)

            # Option
            #tenancy                 = optional(string, "default")
            #disable_api_termination = optional(bool, true)
            #disable_api_stop        = optional(bool, false)
            #instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"

            # Option - Neccessary
            ## Metadata
            #http_endpoint   = optional(string, "enabled")   # "enabled", "disabled"
            #http_tokens     = optional(string, "required")  # "required", "optional"
            #http_put_response_hop_limit = optional(number, 2)
            #instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
            ## 
            user_data                   = local.user_data
            default_tags                = local.common_config.default_tags
            #tags                        = optional(map(string), null)
        }
    }
}