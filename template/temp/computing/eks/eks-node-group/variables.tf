variable "cluster_name" { type = string }
variable "node_group_name" { type = string }
variable "node_role_arn" { type = string }
variable "subnet_ids" { type = list(string) }
variable "capacity_type" { type = string default = "ON_DEMAND" }
variable "instance_types" { type = list(string) }
variable "launch_template_id" { type = string }
variable "launch_template_version" { type = string }
variable "desired_size" { type = number }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "max_unavailable" { type = number default = 1 }
variable "labels" { type = map(string) default = {} }
variable "taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}
variable "tags" { type = map(string) default = {} }
