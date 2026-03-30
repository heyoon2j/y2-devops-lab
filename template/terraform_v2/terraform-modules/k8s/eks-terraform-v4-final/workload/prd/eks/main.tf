provider "aws" {
  region = "ap-northeast-2"
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.ca)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
    }
  }
}

# KMS
module "kms" {
  source = "../../../modules/kms"

  name        = "prd-myapp-eks-cluster-key"
  description = "EKS Cluster Encryption Key"
}

# CloudWatch
module "cloudwatch" {
  source = "../../../modules/cloudwatch"

  cluster_name = "prd-myapp-eks-cluster"
}

# EKS Cluster
module "eks_cluster" {
  source = "../../../modules/eks-cluster"

  cluster_name     = "prd-myapp-eks-cluster"
  cluster_role_arn = var.cluster_role_arn
  private_subnets  = var.private_subnets
  kms_key_arn      = module.kms.key_arn
}

# NodeGroup
module "nodegroup_default" {
  source = "../../../modules/nodegroup"

  cluster_name   = module.eks_cluster.cluster_name
  node_role_arn  = var.node_role_arn
  subnets        = var.private_subnets

  desired_size   = 2
  max_size       = 5
  min_size       = 2
  instance_types = ["t3.medium"]
}

# IRSA ALB
module "irsa_alb" {
  source = "../../../modules/irsa"

  name               = "alb-irsa"
  oidc_provider_arn  = var.oidc_provider_arn
  oidc_provider      = var.oidc_provider
  service_account    = "system:serviceaccount:kube-system:aws-load-balancer-controller"
}

# ALB
module "alb" {
  source = "../../../modules/addon-alb"

  cluster_name         = module.eks_cluster.cluster_name
  service_account_name = "aws-load-balancer-controller"
}

# IRSA FluentBit
module "irsa_fluentbit" {
  source = "../../../modules/irsa"

  name              = "fluentbit-irsa"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider     = var.oidc_provider
  service_account   = "system:serviceaccount:amazon-cloudwatch:aws-for-fluent-bit"
}

# FluentBit
module "fluentbit" {
  source = "../../../modules/addon-fluentbit"

  service_account_name = "aws-for-fluent-bit"
}