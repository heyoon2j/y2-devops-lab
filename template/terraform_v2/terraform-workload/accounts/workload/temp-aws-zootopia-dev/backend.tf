terraform {
  backend "s3" {
    bucket = "terraform-state"
    key = "workload/temp-aws-zootopia-dev/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
