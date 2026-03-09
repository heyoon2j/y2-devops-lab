locals {
  account_name = "temp-aws-zootopia-prd"
  account_id = "222222222222"
  env = "prd"
  region = "ap-northeast-2"

  config = {
    tags = {
      env = "prd"
    }
  }
}
