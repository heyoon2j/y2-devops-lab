# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Role Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "name" {
    description = "Role Name"
    type = string
}

variable "description" {
    description = "Role Description"
    type = string
    default = null
}

variable "path" {
    description = "Role Distrubution"
    type = string
    default = "/"
}

variable "max_session_duration" {
    description = "Max session duration (Default: 3600, Range: 3600 - 43200)"
    type = number
    default = 3600
}

variable "force_detach_policies" {
    description = "Whether or not to detach the policy when deleting a role"
    type = bool
    default = false
}

variable "assume_role_policy" {
    description = "Assume Role Policy"
    type = string
}

variable "inline_policy" {
    description = "Inline Policy"
    type = map(object({
        name = string
        policy = string
    }))
    default = null
}

variable "permissions_boundary" {
    description = "Policy ARN for permissions boundary"
    type = string
    default = null
}

variable "tags" {
    description = "Tags"
    type = map(any)
    default = null
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Attachment Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "policy_arn_custom" {
    description = "Policy ARN - Custom"
    type = map(string)
    default = null
}

variable "policy_arn_aws" {
    description = "Policy ARN - AWS"
    type = map(string)
    default = null
}