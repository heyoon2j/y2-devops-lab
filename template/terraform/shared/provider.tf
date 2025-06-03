##############################################################################################
provider "aws" {
    region      = local.aws_region
    profile     = local.aws_profile
  
    assume_role {
        role_arn        = "arn:aws:iam::${local.aws_account_id}:role/${local.assume_role_name}"
        session_name    = local.aws_profile
    }
}

##############################################################################################
##############################################################################################
/*
provider "aws_beta" {
    alias = "cloud-poc-apn2"
    region = "ap-northeast-2"
    # profile = "default"
    # shared_config_files = ["/Users/tf_user/.aws/config"]
    # shared_credentials_files = ["/Users/tf_user/.aws/config"]
}
*/