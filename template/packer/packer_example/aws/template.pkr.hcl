packer {
  # Packer Version
  required_version = ">= 1.9.0"

  # Plugin Version
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "pkr.hcl" "include" {
  path = "../templates/shared/build_common.pkr.hcl"
}

source "pkr.hcl" "aws" {
  path = "../templates/local/aws.pkr.hcl"
}
