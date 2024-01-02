# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Network Firewall
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
/*
Args:
name - (Required, Forces new resource) A friendly name of the firewall.

vpc_id - (Required, Forces new resource) The unique identifier of the VPC where AWS Network Firewall should create the firewall.

delete_protection - (Optional) A boolean flag indicating whether it is possible to delete the firewall. Defaults to false.

description - (Optional) A friendly description of the firewall.

encryption_configuration - (Optional) KMS encryption configuration settings. See Encryption Configuration below for details.
    - type : CUSTOMER_KMS / AWS_OWNED_KMS_KEY
    - key_id : 
firewall_policy_arn - (Required) The Amazon Resource Name (ARN) of the VPC Firewall policy.

firewall_policy_change_protection - (Option) A boolean flag indicating whether it is possible to change the associated firewall policy. Defaults to false.

subnet_change_protection - (Optional) A boolean flag indicating whether it is possible to change the associated subnet(s). Defaults to false.

subnet_mapping - (Required) Set of configuration blocks describing the public subnets. Each subnet must belong to a different Availability Zone in the VPC. AWS Network Firewall creates a firewall endpoint in each subnet. See Subnet Mapping below for details.
    - ip_address_type : "DUALSTACK", "IPV4"
    - subnet_id : 
tags - (Optional) Map of resource tags to associate with the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.

*/
variable "firewall" {
    description = "Firewall Information"
    type = object({
        name = string
        description = optional(string, null)
        vpc_id = string
        subnet_mapping = map(object({
            subnet_id = string
            #ip_address_type = string #optional(string, "IPV4")      # IPV4, DUALSTACK
        }))
        subnet_change_protection = optional(bool, true)
        #encryption_configuration = optional(object({
        #    type = string                                   # CUSTOMER_KMS, AWS_OWNED_KMS_KEY
        #    key_id = optional(string, null)
        #}), null)
        #firewall_policy_arn = string
        firewall_policy_change_protection = optional(bool, false)
        delete_protection = optional(bool, true)
        tags = optional(map(any), null)
    })
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Network Firewall Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "firewall_policy" {
    description = "Firewall's policy"
    type = object({
        name = string
        description = optional(string, null)
        # encryption_configuration = optional(object({
        #    type = string                                   # CUSTOMER_KMS, AWS_OWNED_KMS_KEY
        #    key_id = optional(string, null)
        # }), null)
        # policy_variables = optional(map(object({
        #     key = string
        #     ip_set = list(string)
        # })), null)
        stateless_default_actions =  list(string)
        stateless_fragment_default_actions = list(string)
        stateless_rule_group_reference = optional(map(object({
            priority = number
            resource_arn = string
        })), null)
        #stateless_custom_action = optional(object({
        #    ip_sets = list(string)
        #    port_sets = list(string)
        #}))
        stateful_engine_options = object({
            rule_order = optional(string, "STRICT_ORDER")      # DEFAULT_ACTION_ORDER, STRICT_ORDER
            #stream_exception_policy = optional(string, "DROP") # DROP, CONTINUE, REJEC
        })
        stateful_default_actions = optional(list(string), null)      
        stateful_rule_group_reference = optional(map(object({
            priority = number
            resource_arn = string
        })), null)
        tags = optional(map(any),null)
    })
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging Configuration
# Type : S3 / CloudWatch / Kinesis
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "log_destination_type" {
    description = "Network Firewall logging - Flow/Alert"
    type = string
    default = null
}

variable "firewall_logging" {
    description = "Network Firewall logging - Flow/Alert"
    type = map(object({
        log_type = optional(string, null)
        log_destination = optional(map(any), null)
    }))
    default = null
}
