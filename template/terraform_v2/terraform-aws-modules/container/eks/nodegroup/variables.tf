variable "cluster_name" {}
variable "name" {}

variable "node_role_arn" {}
variable "subnet_ids" {}
variable "ami_type" {
  type = string
}
variable "instance_types" {
  type = list(string)
}

variable "capacity_type" {
  type = string
}

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