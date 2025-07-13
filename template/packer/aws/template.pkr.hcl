packer {
  required_version = ">= 1.9.0"
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "pkr.hcl" "aws_template" {
  path = "../module/aws.pkr.hcl"
}
