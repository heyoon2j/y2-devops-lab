generate "backend" {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
terraform {
    backend "s3" {
        bucket         = "${get_env("bucket")}"
        key            = "${path_relative_to_include()}/terraform.tfstate"
        region         = "${get_env("region", "ap-northeast-2")}"
        encrypt        = true
        dynamodb_table = "my-lock-table"
    }
}
EOF
}