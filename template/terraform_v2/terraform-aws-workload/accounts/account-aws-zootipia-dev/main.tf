module "platform_eks" {
  source = "../../../interface/platform-eks"

  cluster = {
    name             = "prd-savanna-eks-cluster"
    role_arn         = "arn:aws:iam::123456789012:role/eks-cluster-role"
    subnets          = ["subnet-aaa", "subnet-bbb"]
    kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/xxxx"
  }

  aws_addons = {
    vpc_cni = {
      enabled = true
      version = "v1.15.4-eksbuild.1"

      config = {
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
        }
      }
    }

    coredns = {
      enabled = true
      version = "v1.10.1-eksbuild.2"
    }

    kube_proxy = {
      enabled = true
      version = "v1.29.0-eksbuild.1"
    }

    ebs_csi = {
      enabled = true
      version = "v1.26.0-eksbuild.1"
    }
  }

  helm_addons = {
    metrics_server = {
      enabled    = true
      repository = "https://kubernetes-sigs.github.io/metrics-server"
      chart      = "metrics-server"
    }

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
