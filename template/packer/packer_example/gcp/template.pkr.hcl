packer {
  required_version = ">= 1.9.0"
}

source "pkr.hcl" "include" {
  path = "../templates/shared/build_common.pkr.hcl"
}

source "pkr.hcl" "gcp" {
  path = "../templates/local/gcp.pkr.hcl"
}
