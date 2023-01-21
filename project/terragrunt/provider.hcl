generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite"
    contents = <<EOF
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.40.0"
            configuration_aliases = [ aws.apn2, aws.aps1 ]
        }
    }
}

provider "aws" {
    alias = "apn2"
    region = "ap-northeast-2"
    #assume_role { role_arn = "" }
    #profile = ""
    #allowed_account_ids = ["1234567890"]
}

provider "aws" {
    alias = "aps1"
    region = "ap-south-1"
    #assume_role { role_arn = "" }
    #profile = ""
    #allowed_account_ids = ["1234567890"]
}
EOF
}

