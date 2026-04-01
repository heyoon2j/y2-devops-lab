module "cluster" {
  source = "../../../terraform-modules/container/eks/eks-cluster"

  name             = var.cluster.name
  role_arn         = var.cluster.role_arn
  subnets          = var.cluster.subnets
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
  prevent_destroy  = false
}


module "addons" {
  for_each = var.addons

  source = "../../../terraform-modules/container/eks/addon-core"

  cluster_name = var.cluster.name
  name         = each.key
}