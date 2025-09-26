# Default
aws_region      = "ap-northeast-2"
ami_name        = "testaws-os-${var.os_name}-base-${formatdate("241216", timestamp())}"
aws_profile     = ""
cloud           = "aws"
instance_type   = "t3.medium"
subnet_id       = ""
security_group_id = ""