terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.40.0"
            configuration_aliases = [ aws.apn2, aws.aps1 ]
        }
    }

    backend "s3" {
        bucket = "s3-proj-temp"
        key    = "backend/${terraform.workspace}/terraform.tfstate"
        region = "ap-northeast-2"
    }
    # 현재 Backend를 Workspace 별로 구분하기 위해서는 CLI를 써야 된다.
}

provider "aws" {
    alias = "apn2"
    region = "ap-northeast-2"
    #assume_role { role_arn = "" }
    #profile = ""

    default_tags {
        tags = {
            Environment = "Test"
            Name = "Provider Tag"
        }
    }
}

provider "aws" {
    alias = "aps1"
    region = "ap-south-1"
    #assume_role { role_arn = "" }
    #profile = ""

    default_tags {
        tags = {
            Environment = "Test"
            Name = "Provider Tag"
        }
    }
}