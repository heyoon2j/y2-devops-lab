terraform {
    backend "s3" {
        bucket         = "${local.root_cfg.locals.backend["bucket"]}"
        key            = "/${basename(abspath(path.module))}/terraform.tfstate"
        region         = "ap-northeast-2"
        encrypt        = "true"
        # kms_key_id     = "arn:"       # 특정 KMA 지정시
        profile        = "tfstate-s3-profile" 
    }
}