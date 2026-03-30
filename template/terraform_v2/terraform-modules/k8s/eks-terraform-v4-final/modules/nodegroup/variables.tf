variable "cluster_name" {}
variable "node_role_arn" {}
variable "subnets" { type = list(string) }
variable "desired_size" {}
variable "max_size" {}
variable "min_size" {}
variable "instance_types" { type = list(string) }