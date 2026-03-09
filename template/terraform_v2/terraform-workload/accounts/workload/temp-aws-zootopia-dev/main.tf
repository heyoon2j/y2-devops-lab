module "zootopia" {
  source = "../../../projects/zootopia"

  env = local.env
  config = local.config
  cluster_role_arn = data.aws_iam_role.eks_cluster.arn
  subnet_ids = data.aws_subnets.shared.ids
  security_group_ids = [data.aws_security_group.baseline.id]
}
