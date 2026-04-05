variable "cluster_name" {}
variable "name" {}

variable "node_role_arn" {}
variable "subnet_ids" {}

variable "instance_types" {
  type = list(string)
}

variable "capacity_type" {}

variable "desired_size" {}
variable "min_size" {}
variable "max_size" {}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "taints" {
  type    = list(any)
  default = null
}