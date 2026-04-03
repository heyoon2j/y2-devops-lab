variable "cluster_name" {
  type = string
}

variable "name" {
  type = string
}

variable "addon_version" {
  type = string
}

resolve_conflicts_on_create {
  type = string
}

resolve_conflicts_on_update {
  type = string
}

variable "config" {
  type    = any
  default = null
}