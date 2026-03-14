variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cidr_blocks" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
