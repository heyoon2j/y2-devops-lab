resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  version = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = var.security_group_ids
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      provider {
        key_arn = var.kms_key_arn
      }

      resources = ["secrets"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}
