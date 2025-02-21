variable "ec2_instance" {
    description = "EC2 Instance Variable"
    # default = 
    type = object({
        description     = optional(string, null)

        name            = string
        instance_type   = string
        image_name      = string
        key_name        = optional(string, null)

        # Network
        subnet_name                 = string
        sg_names                    = list(string)
        source_dest_check           = optional(bool, true)
        ## Static or Dynamic IP
        private_ip_static_enabled   = optional(bool, false)
        private_ip_static_list      = optional(list(string), null)
        private_ip_dynamic          = optional(number, 0)
        ## Place Group
        placement_group             = optional(string, null)
        placement_partition_number  = optional(string, null)

        # Option
        tenancy                 = optional(string, "default")
        disable_api_termination = optional(bool, true)
        disable_api_stop        = optional(bool, false)
        instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"

        # Option - Neccessary
        ## Metadata
        http_endpoint               = optional(string, "enabled")   # "enabled", "disabled"
        http_tokens                 = optional(string, "required")  # "required", "optional"
        http_put_response_hop_limit = optional(number, 2)
        instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
        ## Default Options
        user_data                   = optional(string, null)
        default_tags                = optional(map(string), null)
        tags                        = optional(map(string), null)
    })
}