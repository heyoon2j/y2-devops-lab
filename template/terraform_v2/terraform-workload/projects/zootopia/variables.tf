variable "env" {}
variable "config" { type = map(any) }
variable "cluster_role_arn" {}
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
