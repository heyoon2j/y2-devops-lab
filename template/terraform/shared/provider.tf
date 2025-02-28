##############################################################################################

provider "aws" {
    alias = "common-prd-apn2"
    region = "ap-northeast-2"
    profile = ""
}

provider "aws" {
    alias = "common-poc-apn2"
    region = "ap-northeast-2"
    profile = ""
    assume_role {
        role_arn = ""
        session_name = ""
    }
}

provider "aws" {
    alias = "common-prd-apn1"
    region = "ap-northeast-1"
    profile = ""
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