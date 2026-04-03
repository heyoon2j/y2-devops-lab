locals {
  has_config = var.config != null && length(var.config) > 0

  configuration_values = local.has_config ? jsonencode(var.config) : null
}

resource "aws_eks_addon" "this" {
  cluster_name  = var.cluster_name
  addon_name    = var.name
  addon_version = var.addon_version
  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
  configuration_values = local.configuration_values
}