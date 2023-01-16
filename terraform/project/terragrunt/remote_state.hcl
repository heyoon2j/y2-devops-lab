generate "backend" {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
terraform {
    backend "s3" {
        bucket         = "${get_env("bucket", "s3-proj-aps1-tfstate")}"
        key            = "${path_relative_to_include("remote_state.hcl")}/terraform.tfstate"
        region         = "${get_env("region", "ap-south-1")}"
        encrypt        = true
    }
}
EOF
}