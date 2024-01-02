variable "sg" {
    description = "Security Group Information"
    type = object({
        name = string
        description = string
        vpc_id = string
        tags = map(any)
    })
}

variable "ingress" {
    description = "Security Group's Inbound"
    type = map(object({
        description = optional(string, null)
        from_port = number
        to_port = number
        protocol = string
        cidr_blocks = list(string)
    }))
}

variable "egress" {
    description = "Security Group's Outbound"
    type = map(object({
        description = optional(string, null)
        from_port = number
        to_port = number
        protocol = string
        cidr_blocks = list(string)
    }))
}
