variable "rule_type" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "from_port" {
  type = number
}

variable "to_port" {
  type = number
}

variable "protocol" {
  type = string
}

variable "cidr_ipv4" {
  type    = string
  default = null
}

variable "prefix_list_id" {
  type    = string
  default = null
}

variable "referenced_security_group_id" {
  type    = string
  default = null
}