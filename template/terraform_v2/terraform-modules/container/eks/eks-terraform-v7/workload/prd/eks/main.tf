provider "aws" {
  region = var.region
}

module "platform_eks" {
  source = "../../../modules/platform-eks"

  cluster = {
    name             = var.cluster.name
    role_arn         = var.cluster.role_arn
    subnets          = var.cluster.subnets
    endpoint_private = var.cluster.endpoint_private
    endpoint_public  = var.cluster.endpoint_public
    ip_family        = var.cluster.ip_family
    service_cidr     = var.cluster.service_cidr
    auth_mode        = var.cluster.auth_mode
    kms_key_arn      = var.cluster.kms_key_arn
    log_types        = var.cluster.log_types
  }
}

# addons (interface-driven)
module "addons" {
  for_each = var.addons

  source = "../../../modules/addon-core"

  cluster_name = var.cluster.name
  name         = each.key
}