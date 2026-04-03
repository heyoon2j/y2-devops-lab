variable "name" {
  type = string
}

variable "repository" {
  type = string
}

variable "chart" {
  type = string
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "values" {
  type    = any
  default = null
}

variable "set_values" {
  type    = map(string)
  default = null
}