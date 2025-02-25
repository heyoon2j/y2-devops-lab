variable "sg" {
    description = "Security Group Information"
    type = object({
        name        = string
        description = optional(string, null)
        vpc_name    = string
        tags            = optional(map(any), null)
        default_tags    = optional(map(any), null)
    })
}

variable "ingress" {
    description = "Security Group's Inbound"
    type = map(object({
        description     = optional(string, null)
        from_port       = optional(number, null)
        to_port         = optional(number, null)
        protocol        = string
        cidr_ipv4                       = optional(string, null)
        prefix_list_id                  = optional(string, null)
        referenced_security_group_id    = optional(string, null)
        tags            = optional(map(any), null)
    }))
}

variable "egress" {
    description = "Security Group's Outbound"
    type = map(object({
        description     = optional(string, null)
        from_port       = optional(number, null)
        to_port         = optional(number, null)
        protocol        = string
        cidr_ipv4                       = optional(string, null)
        prefix_list_id                  = optional(string, null)
        referenced_security_group_id    = optional(string, null)
        tags            = optional(map(any), null)
    }))
}
