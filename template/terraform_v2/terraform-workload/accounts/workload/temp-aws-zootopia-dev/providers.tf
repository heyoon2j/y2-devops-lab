provider "aws" {
  region = local.region

  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/terraform-deploy-role"
  }
}
