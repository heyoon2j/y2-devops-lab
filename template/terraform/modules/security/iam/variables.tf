variable "role" {
    description = "Role Information"
    type = list(object({
        name                    = string
        assume_role_policy      = string
    }))
}

variable "user_policy" {
    description = "Information for attachment TGW Peering"
    type = list(object({
        name = string
        path = list(string)
        description = list(string)
        json = string
        attachment_roles = list(string)
        attachment_users = list(string)
        attachment_groups = list(string)
    }))
}

variable "aws_policy" {
    description = "Information for attachment TGW Peering"
    type = list(object({
        name = string
        arn = string
        attachment_roles = list(string)
        attachment_users = list(string)
        attachment_groups = list(string)
    }))
}

##################################################################
## Config Input
# variable "proj_region" {
#     description = "Project Region"
#     type = string
#     validation {
#         condition = can(regex("^[a-z]{2}[1-3]{1}$", var.proj_region))
#         error_message = "Like ap2, as1 ..."
#     }
# }

# variable "proj_name" {
#     description = "Project Name"
#     type = string
# }

# variable "proj_env" {
#     description = "Project Environment"
#     type = string
#     validation { 
#         condition = contains(["dev", "stg", "prd"], var.proj_env)
#         error_message = "Only use dev, stg, prd"
#     }
# }
