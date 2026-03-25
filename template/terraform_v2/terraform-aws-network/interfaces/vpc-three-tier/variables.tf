variable "vpc_cidr" { type = string }
variable "vpc_name" { type = string }

variable "subnets" {
  type = map(object({
    cidr_block   = string
    availability_zone     = string
    map_public_ip_on_launch = bool
  }))
}

variable "features" {
  type = object({
    subnet = bool
    nacl   = bool
  })
}

variable "tags" { type = map(string) }


variable "nacl_ingress_rule" {
  type = map(object({
    rule_number    = number
    protocol       = number
    rule_action    = string
    cidr_block     = string
    from_port = number
    to_port   = number
  }))
}