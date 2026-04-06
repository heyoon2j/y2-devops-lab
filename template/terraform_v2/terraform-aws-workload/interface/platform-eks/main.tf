module "cluster" {
  source = "../../../terraform-aws-modules/container/eks/eks-cluster"

  name             = var.cluster.name
  cluster_version  = var.cluster.version
  role_arn         = var.cluster.role_arn
  subnets          = var.cluster.subnets
  security_group_ids = var.cluster.security_group_ids
  endpoint_private = true
  endpoint_public  = false
  ip_family        = "ipv4"
  service_cidr     = "172.20.0.0/16"
  auth_mode        = "API_AND_CONFIG_MAP"
  kms_key_arn      = var.cluster.kms_key_arn
  log_types        = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}


##########################################
# AWS Add-ons
##########################################
module "aws_addons" {
  for_each = {
    for k, v in var.aws_addons :
    k => v if v.enabled
  }

  source = "../../../terraform-aws-modules/container/eks/addon-aws"

  cluster_name = var.cluster.name
  name         = replace(each.key, "_", "-")

  addon_version = each.value.version
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  config  = try(each.value.config, null)
}

##########################################
# Helm Add-ons
##########################################
module "helm_addons" {
  for_each = {
    for k, v in var.helm_addons :
    k => v if v.enabled
  }

  source = "../../../terraform-aws-modules/container/eks/addon-helm"

  name       = replace(each.key, "_", "-")
  repository = each.value.repository
  chart      = each.value.chart
  namespace  = try(each.value.namespace, "kube-system")

  values     = try(each.value.values, null)
  set_values = try(each.value.set_values, null)
}


module "service_account" {
  for_each = var.irsa

  source = "../../../terraform-aws-modules/container/eks/service-account"

  name      = each.value.name
  namespace = each.value.namespace

  role_arn = each.value.role_arn
}


module "node_groups" {
  for_each = var.node_groups

  source = "../../../terraform-aws-modules/container/eks/nodegroup"

  cluster_name = module.cluster.name
  name         = each.key

  ##################################
  # 🔥 바로 사용
  ##################################
  node_role_arn = each.value.node_role_arn

  subnet_ids     = each.value.subnet_ids
  ami_type       = each.value.ami_type
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  desired_size = each.value.desired_size
  min_size     = each.value.min_size
  max_size     = each.value.max_size

  labels = try(each.value.labels, {})
  taints = try(each.value.taints, null)
}