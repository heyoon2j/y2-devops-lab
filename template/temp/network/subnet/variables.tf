variable "vpc_id" {
  type = string
}

variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "ipv6_cidr" {
	type 		= string
	default = null 
}

variable "az" {
  type = string
}

variable "map_public_ip_on_launch" {
  type 		= bool
	default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}