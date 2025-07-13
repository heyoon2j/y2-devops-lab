packer {
  required_version = ">= 1.9.0"
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "pkr.hcl" "gcp_template" {
  path = "../module/gcp.pkr.hcl"
}
