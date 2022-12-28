generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite"
    contents = <<EOF
provider "aws" {
  region              = "us-east-1"
  version             = "= 2.3.1"
  allowed_account_ids = ["1234567890"]
}
EOF
}

