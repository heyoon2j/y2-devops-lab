variable "cluster_name" { type = string }
variable "cluster_role_arn" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) default = [] }
variable "kubernetes_version" { type = string default = "1.30" }
variable "endpoint_private_access" { type = bool default = true }
variable "endpoint_public_access" { type = bool default = false }
variable "kms_key_arn" { type = string default = null }
variable "enabled_cluster_log_types" {
  type = list(string)
  default = ["api", "audit", "authenticator"]
}
variable "tags" { type = map(string) default = {} }
