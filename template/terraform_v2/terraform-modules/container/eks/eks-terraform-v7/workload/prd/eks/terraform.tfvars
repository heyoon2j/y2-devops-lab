region = "ap-northeast-2"

cluster = {
  name             = "prd-myapp-eks-cluster"
  role_arn         = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnets          = ["subnet-aaa", "subnet-bbb"]

  endpoint_private = true
  endpoint_public  = false

  ip_family    = "ipv4"
  service_cidr = "172.20.0.0/16"

  auth_mode   = "API_AND_CONFIG_MAP"
  kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/xxxx"

  log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

addons = {
  vpc_cni = {
    enabled = true
    version = "v1.15.4-eksbuild.1"

    config = {
      env = {
        WARM_PREFIX_TARGET = "2"
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