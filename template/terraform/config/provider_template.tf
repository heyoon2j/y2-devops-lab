terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.40.0"
        }

        aws_beta = {
            source  = "hashicorp/aws"
            version = "~> 4.40.0"
        }
    }

/*
    backend "s3" {
        bucket = "s3-proj-temp"
        key    = "backend/${terraform.workspace}/terraform.tfstate"
        region = "ap-northeast-2"
    }
*/
    # 현재 Backend를 Workspace 별로 구분하기 위해서는 CLI를 써야 된다.
}

provider "aws" {
    alias = "apn2"
    region = "ap-northeast-2"

}

provider "aws" {
    alias = "apn1"
    region = "ap-northeast-1"
}


provider "aws_beta" {
    alias = "apn2"
    region = "ap-northeast-2"
    # profile = "default"
    # shared_config_files = ["/Users/tf_user/.aws/config"]
    # shared_credentials_files = ["/Users/tf_user/.aws/config"]
}