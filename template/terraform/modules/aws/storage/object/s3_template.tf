/*
# S3
1. S3
    1) Bucket 생성
    2) ACL & Policy 설정
    3) 암호화 설정
    4) Object의 Life cycle 설정
    5) Logging 설정 (필요시)
*/


## Input Value



## Outpu Value




############################################################
# 1. S3
/*
'S3 Bucket Resource'

Args:
    bucket
        description = "Bucket name"
        type = string
*/

resource "aws_s3_bucket" "s3-proj-temp" {
    bucket = "my-tf-test-bucket"
    #object_lock_enabled = false

    tags = {
        Name        = "My bucket"
        Environment = "Dev"
    }
}

resource "aws_s3_bucket_acl" "s3-acl-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id
    acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "s3-pub-access-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id

    #새로운 Public ACL 차단
    block_public_acls       = true
    # 기존 Public ACL 차단
    ignore_public_acls      = true
    # 새로운 Public bucket & access point 차단
    block_public_policy     = true
    # 기존 Public bucket & access point 차단
    restrict_public_buckets = true
}

/*
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
    bucket = aws_s3_bucket.example.id
    policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
    statement {
        principals {
            type        = "AWS"
            identifiers = ["123456789012"]
        }

        actions = [
            "s3:GetObject",
            "s3:ListBucket",
        ]

        resources = [
            aws_s3_bucket.example.arn,
            "${aws_s3_bucket.example.arn}/*",
        ]
    }
}
*/


/*
'S3 Bucket encryption Resource'

Args:
    bucket
        description = "Bucket name"
        type = string

    kms_master_key_id
        description = "AWS KMS ARN for S3"
        type = string
        validation { "^arn:*"}    

    sse_algorithm
        description = "SSE Algorithm"
        type = number
        default = "aws:kms"
        validation { "aws.kms", "AES256" }

    bucket_key_enabled
        description = "Whether or not to use bucket key"
        type = bool
        default = true
        validation { true (Default), false }
*/

resource "aws_s3_bucket_server_side_encryption_configuration" "s3-encrypt-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id

    rule {
        apply_server_side_encryption_by_default {
            kms_master_key_id = ""
            sse_algorithm     = "aws:kms"
        }
        bucket_key_enabled = true
    }
}



/*
'S3 Bucket Resource'

Args:
    bucket
        description = "Bucket name"
        type = string
        #validation { }

    rule
        description = "Lifecycle Rule"
        type = 
        #validation { }
*/

resource "aws_s3_bucket_lifecycle_configuration" "s3-lifecycle-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id

    rule {
        id = "log"

        filter {
            and {
                prefix = "log/"

                tags = {
                    rule      = "log"
                    autoclean = "true"
                }
            }
        }

        status = "Enabled"

        transition {
            days          = 30
            storage_class = "STANDARD_IA"
        }

        transition {
            days          = 60
            storage_class = "GLACIER"
        }

        expiration {
            days = 90
        }
    }

    rule {
        id = "tmp"

        filter {
            prefix = "tmp/"
        }

        expiration {
            date = "2023-01-13T00:00:00Z"
        }

        status = "Enabled"
    }
}
