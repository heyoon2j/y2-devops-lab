variable "cluster_name" {}
variable "cluster_role_arn" {}
variable "private_subnets" { type = list(string) }
variable "kms_key_arn" {}