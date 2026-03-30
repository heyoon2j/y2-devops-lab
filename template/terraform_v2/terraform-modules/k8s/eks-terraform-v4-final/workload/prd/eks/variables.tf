variable "cluster_role_arn" {}
variable "node_role_arn" {}
variable "private_subnets" { type = list(string) }
variable "oidc_provider_arn" {}
variable "oidc_provider" {}