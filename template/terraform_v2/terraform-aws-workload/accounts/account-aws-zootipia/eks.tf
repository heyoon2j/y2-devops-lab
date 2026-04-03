module "platform_eks" {
  source = "../../interface/platform-eks"

  cluster = {
    name             = "prd-savanna-eks-cluster"
    version          = "1.35"
    role_arn         = "arn:aws:iam::123456789012:role/eks-cluster-role"
    subnets          = ["subnet-aaa", "subnet-bbb"]
    security_group_ids = ["sg-12345678", "sg-abcdef12" ]
    kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/xxxx"
  }

  aws_addons = {
    vpc_cni = {
      enabled = true
      version = "v1.21.1-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      config = {
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
        }
      }
    }

    coredns = {
      enabled = true
      version = "v1.13.2-eksbuild.3"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      config  = {}
    }

    kube_proxy = {
      enabled = true
      version = "v1.35.0-eksbuild.2"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      config  = {}
    }

    ebs_csi = {
      enabled = true
      version = "v1.35.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      config  = {}
    }

    metrics_server = {
      enabled = true
      version = "v0.8.1-eksbuild.5"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      config  = {}
    }
  }

  helm_addons = {
    aws_load_balancer_controller = {
      enabled    = true
      repository = "https://aws.github.io/eks-charts"
      chart      = "aws-load-balancer-controller"

      set_values = {
        clusterName = "prd-myapp-eks-cluster"
      }
    }
  }

  irsa = {
    alb_controller = {
      namespace = "kube-system"
      name      = "aws-load-balancer-controller"

      role_arn = "arn:aws:iam::123456789012:role/alb-controller-role"
    }

    ebs_csi = {
      namespace = "kube-system"
      name      = "ebs-csi-controller-sa"

      role_arn = "arn:aws:iam::123456789012:role/ebs-csi-role"
    }
  }
}