module "eks" {
  count = lookup(var.features, "eks", false) ? 1 : 0
  source = "../../modules/workload/eks"

  name = var.naming.eks
  cluster_role_arn = var.cluster_role_arn
  subnet_ids = var.subnet_ids
  security_group_ids = var.security_group_ids
  tags = var.tags
}
