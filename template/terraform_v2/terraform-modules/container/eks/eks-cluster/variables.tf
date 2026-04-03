variable "name" {}
variable "role_arn" {}
variable "subnets" { type = list(string) }
variable "cluster_version" {
  type = string
}

variable "endpoint_private" { type = bool }
variable "endpoint_public"  { type = bool }

variable "ip_family" {}
variable "service_cidr" {}

variable "auth_mode" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "log_types" {
  type = list(string)
}