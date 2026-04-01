variable "region" {}

variable "cluster" {
  type = object({
    name             = string
    role_arn         = string
    subnets          = list(string)
    endpoint_private = bool
    endpoint_public  = bool
    ip_family        = string
    service_cidr     = string
    auth_mode        = string
    kms_key_arn      = string
    log_types        = list(string)
  })
}

variable "addons" {
  type = map(object({
    enabled = bool
    version = string
    config  = optional(any)
  }))
}