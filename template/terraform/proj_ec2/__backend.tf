/*
terraform {
    backend "s3" {
        bucket         = "${local.root_cfg.locals.backend["bucket"]}"
        key            = "${path_relative_to_include("remote_state.hcl")}/terraform.tfstate"
        region         = "${local.root_cfg.locals.backend["region"]}"
        encrypt        = "${local.root_cfg.locals.backend["encrypt"]}"
    }
}
*/