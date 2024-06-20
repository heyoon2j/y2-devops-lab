/*
variable "launch_temp" {
    description = "Launch Template"
    type = object({
        template_name = string
        image_id = string
        instance_type = string 
        key_name = string
        associate_public_ip_address = bool
        vpc_security_group_ids = list(string)
        block_device_mappings = map(any)
        iam_instance_profile = map(any)
        private_dns_name_options = map(any)
        instance_initiated_shutdown_behavior = string
        hibernation_options =  map(any)
        disable_api_stop = bool
        disable_api_termination = bool
        monitoring = map(any)
        ebs_optimized = bool
        metadata_options = map(any)
        user_data = string
        tag_specifications = map(any)

    })
}
*/