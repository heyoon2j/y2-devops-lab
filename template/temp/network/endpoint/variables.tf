variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "service_name" {
  type = string
}

variable "endpoint_type" {
  type      = string
  default   = "Interface"
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "route_table_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}