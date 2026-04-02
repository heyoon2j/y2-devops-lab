variable "cluster_name" {
  type = string
}

variable "name" {
  type = string
}

variable "version" {
  type = string
}

variable "config" {
  type    = any
  default = null
}