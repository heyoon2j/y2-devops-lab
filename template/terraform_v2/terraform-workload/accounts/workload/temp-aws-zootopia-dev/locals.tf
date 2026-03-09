locals {
  account_name = "temp-aws-zootopia-dev"
  account_id = "111111111111"
  env = "dev"
  region = "ap-northeast-2"

  config = {
    tags = {
      env = "dev"
    }
  }
}
