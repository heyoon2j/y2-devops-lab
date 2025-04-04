variable "instance" {
    description = "EC2 Instance Variable"
    # default = 
    type = object({
        description     = optional(string, null)

        name            = string
        instance_type   = string
        image_name      = string
        key_name        = optional(string, null)

        # Network
        availability_zone           = string
        subnet_name                 = string
        sg_names                    = list(string)
        source_dest_check           = optional(bool, true)
        ## Static or Dynamic IP
        private_ip_static_enabled   = optional(bool, false)
        private_ip_static_list      = optional(list(string), null)
        private_ip_dynamic          = optional(number, 0)
        ## Pbulic
        #associate_public_ip_address = optional(bool, false)
        ## Place Group
        placement_group             = optional(string, null)
        placement_partition_number  = optional(string, null)


        root_volume             = object({
            delete_on_termination       = optional(bool, true)
            encrypted                   = optional(bool, false)
            kms_key_id                  = optional(string, null)
            volume_type                 = optional(string, "gp3")
            volume_size                 = number
            iops                        = optional(number, null)
            throughput                  = optional(number, null)
        })

        add_volume              = optional(object({
            name                        = string
            type                        = optional(string, "gp3")
            size                        = number
            iops                        = optional(number, null)
            throughput                  = optional(number, null)
        }),null)

        # Option
        tenancy                 = optional(string, "default")
        disable_api_termination = optional(bool, true)
        disable_api_stop        = optional(bool, false)
        instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"
        iam_instance_profile                    = optional(string, null)

        # Option - Neccessary
        ## Metadata
        http_endpoint               = optional(string, "enabled")   # "enabled", "disabled"
        http_tokens                 = optional(string, "required")  # "required", "optional"
        http_put_response_hop_limit = optional(number, 2)
        instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
        ## Default Options
        user_data                   = optional(string, null)
        tags                        = optional(map(string), null)
    })
}