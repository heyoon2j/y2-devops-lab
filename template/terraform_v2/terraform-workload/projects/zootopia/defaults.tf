locals {
  default_features = {
    eks = true
    dynamodb = true
    ecr = true
  }

  default_tags = {
    service = "zootopia"
    domain = "workload"
    managed_by = "terraform"
  }
}
