variable "role" {
    description = "Role Information"
    type = object({
        name = string
        assume_role_policy = string
        inline_policy = map(any)
        #managed_policy_arns = list(string)
        permissions_boundary = string
        tags = map(any)
    })
}

variable "attach_policy_custom" {
    description = "Policy created custom attachment"
    type = map(any)
}

variable "attach_policy_aws" {
    description = "Policy managed aws attachment"
    type = map(any)
}