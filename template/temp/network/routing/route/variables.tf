variable "route_table_id" {
  type = string
}

variable "destination_cidr_block" {
  type = string
}

variable "gateway_id" {
  type    = string
  default = null
}

variable "nat_gateway_id" {
  type    = string
  default = null
}

variable "transit_gateway_id" {
  type    = string
  default = null
}

variable "vpc_endpoint_id" {
  type    = string
  default = null
}

variable "network_interface_id" {
  type    = string
  default = null
}

variable "vpc_peering_connection_id" {
  type    = string
  default = null
}

variable "egress_only_gateway_id" {
  type    = string
  default = null
}