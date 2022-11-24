# Provider
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.40.0"
        }
    }
}

provider "aws" {
    region = "ap-south-1"

    default_tags {
        tags = {
            Environment = "Test"
        }
    }
}


# S3 버킷을 생성한다
resource "aws_s3_bucket" "s3_tfstate" {
    bucket = "s3-proj-aps1-tfstate"
}

# S3 버킷의 버저닝 기능 활성화 선언한다.
resource "aws_s3_bucket_versioning" "tfstate" {
    bucket = aws_s3_bucket.s3_tfstate.bucket

    versioning_configuration {
        status = "Enabled"
    }
}

# DynamoDB for terraform state lock
resource "aws_dynamodb_table" "terraform_state_lock" {
    name         = "terraform-lock"
    hash_key     = "LockID"
    billing_mode = "PAY_PER_REQUEST"

    attribute {
        name = "LockID"
        type = "S"
    }
}