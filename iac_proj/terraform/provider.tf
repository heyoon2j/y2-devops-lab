# Provider
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.40.0"
            configuration_aliases = [ aws.apn2, aws.aps1 ]
        }
    }
    # CLI for Backend
    # terraform init -backend-config=PATH
}

provider "aws" {
    alias = "apn2"
    region = "ap-northeast-2"
    
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

    default_tags {
        tags = {
            Environment = "Test"
            Name = "Provider Tag"
        }
    }
}