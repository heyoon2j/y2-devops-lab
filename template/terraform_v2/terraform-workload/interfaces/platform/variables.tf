variable "features" { type = map(bool) }
variable "cluster_role_arn" {}
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "naming" { type = map(string) }
variable "tags" { type = map(string) }
