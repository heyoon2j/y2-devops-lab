variable "domain" {
    description = "Hosted Zone"
    type = string
}

variable "comment" {
    description = "Hosted Zone's comment"
    type = string
    default = "Managed by Terraform"
}

variable "private_vpc" {
    description = "VPC name for creating private hosted zone"
    type = map(string)
}

variable "force_destroy" {
    description = "Enable to force destroy"
    type = bool
    default = false
}

variable "tags" {
    description = "Tags"
    type = map(any)
}

# variable "vpc_assoc" {
#     description = "VPC List for attach to hosted zone"
#     type = map(object({
#         name = string
#     }))
# }