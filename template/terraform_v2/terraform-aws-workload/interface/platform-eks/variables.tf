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
    resolve_conflicts_on_create = string
    resolve_conflicts_on_update = string
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


variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string

    desired_size = number
    min_size     = number
    max_size     = number

    subnet_ids = list(string)

    ##################################
    # 🔥 변경
    ##################################
    node_role_arn = string

    labels = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
  }))
}