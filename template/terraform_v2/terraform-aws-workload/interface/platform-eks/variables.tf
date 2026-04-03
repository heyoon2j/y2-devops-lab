variable "cluster" {
  type = object({
    name             = string
    version          = string
    subnets          = list(string)
    role_arn         = string
    kms_key_arn      = string
  })
}

##########################################
# AWS Add-ons
##########################################
variable "aws_addons" {
  type = map(object({
    enabled = bool
    version = string
    config  = optional(any)
  }))
}

##########################################
# Helm Add-ons
##########################################
variable "helm_addons" {
  type = map(object({
    enabled    = bool
    repository = string
    chart      = string
    namespace  = optional(string)
    values     = optional(any)
    set_values = optional(map(string))
  }))
}

variable "irsa" {
  type = map(object({
    namespace = string
    name      = string

    role_arn = string   # 🔥 직접 입력 (또는 data lookup)
  }))
}