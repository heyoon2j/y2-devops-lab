variable "firewall" {
    description = "Firewall Information"
    type = map(object({
        name = string
        vpc_id = string
        subnet_mapping = map(object({
            subnet_id = string
            ip_address_type = string
        }))
        subnet_change_protection = optional(bool, true)
        encryption_configuration = optional(object(
            type = string
            key_id = string
        ))
        firewall_policy_arn = string
        firewall_policy_change_protection = optional(bool, false)
        delete_protection = optional(bool, true)
        logging_configuration = optional(object({
            log_destination_type = string
            log_type = string
            log_destination = object(any)
        }))
        tags = optional(map(any))
    }))
}

variable "firewall_policy" {
    description = "Firewall's policy"
    type = object({
        name = string

        policy_variables = optional()

        stateless_custom_action = optional(object({
            ip_sets = list(string)
            port_sets = list(string)
        }))
        stateless_default_actions =  list(string)
        stateless_fragment_default_actions = list(string)
        stateless_rule_group_reference = optional(map(object(
            priority = number
            resource_arn = string
        )))

        stateful_engine_options = object(
            rule_order = string
            stream_exception_policy = string
        )
        stateful_default_actions = optional(list(string))            
        stateful_rule_group_reference = optional(map(object(
            priority = number
            resource_arn = string
        )))

        tags = opotional(map(any))
    })
}
