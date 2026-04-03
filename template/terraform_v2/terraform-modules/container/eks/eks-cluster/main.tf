resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = var.role_arn
  version  = var.version

  vpc_config {
    subnet_ids              = var.subnets
    endpoint_private_access = var.endpoint_private
    endpoint_public_access  = var.endpoint_public
  }

  kubernetes_network_config {
    ip_family         = var.ip_family
    service_ipv4_cidr = var.service_cidr
  }

  access_config {
    authentication_mode = var.auth_mode
  }

#  encryption_config {
#    provider {
#      key_arn = var.kms_key_arn
#    }
#    resources = ["secrets"]
#  }

  enabled_cluster_log_types = var.log_types

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}