locals {
    root_cfg = read_terragrunt_config(find_in_parent_folders("root_cfg.hcl"))
}


generate "backend" {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
terraform {
    backend "s3" {
        bucket         = "${local.root_cfg.locals.backend["bucket"]}"
        key            = "${path_relative_to_include("remote_state.hcl")}/terraform.tfstate"
        region         = "${local.root_cfg.locals.backend["region"]}"
        encrypt        = ${local.root_cfg.locals.backend["encrypt"]}
    }
}
EOF
}