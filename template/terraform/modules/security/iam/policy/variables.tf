variable "policy_custom" {
    description = "Information for attachment TGW Peering"
    type = map(object({
        name = string
        path = string
        description = string
        policy = string
    }))
}

variable "policy_boundary" {
    description = "Information for attachment TGW Peering"
    type = map(object({
        name = string
        path = string
        description = string
        policy = string
    }))
}