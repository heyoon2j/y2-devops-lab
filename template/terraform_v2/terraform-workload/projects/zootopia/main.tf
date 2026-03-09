locals {
  final_features = merge(local.default_features, lookup(var.config, "features", {}))
  final_tags = merge(local.default_tags, lookup(var.config, "tags", {}))
}

module "platform" {
  source = "../../interfaces/platform"

  features = local.final_features
  cluster_role_arn = var.cluster_role_arn
  subnet_ids = var.subnet_ids
  security_group_ids = var.security_group_ids

  naming = {
    eks = "temp-workload-${var.env}-zootopia-eks"
  }

  tags = local.final_tags
}
