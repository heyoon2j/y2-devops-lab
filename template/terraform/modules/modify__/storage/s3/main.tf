/*
# S3
1. S3
    1) Bucket 생성
    2) ACL & Policy 설정
    3) 버킷 소유권 설정
    4) 암호화 설정
    5) Object의 Life cycle 설정
    6) Logging 설정 (필요시)
*/


## Input Value



## Outpu Value

locals {
    public_access_block = [
        {
            #새로운 Public ACL 차단
            block_public_acls       = true
            # 새로운 Public bucket & access point 차단
            block_public_policy     = true
            # 기존 Public ACL 차단
            ignore_public_acls      = true
            # 버킷 소유자와 AWS서비스만 해당 버킷 액세스 가능
            restrict_public_buckets = true
        }
    ]
}


############################################################
# 1. S3
/*
'S3 Bucket Resource'

Args:
    bucket
        description = "Bucket name"
        type = string
*/

resource "aws_s3_bucket" "s3-proj" {
    count = length(var.s3)

    bucket = var.s3[count.index]["name"]
    #object_lock_enabled = false

    tags = var.s3[count.index]["tags"]
}

/*
resource "aws_s3_bucket_acl" "s3-acl-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id
    acl    = "private"
}
*/

resource "aws_s3_bucket_public_access_block" "s3-public-access-proj" {
    count = length(var.s3)

    bucket = aws_s3_bucket.s3-proj[count.index].id

    #새로운 Public ACL 차단
    block_public_acls       = var.s3[count.index]["block_public_acls"]
    # 기존 Public ACL 차단
    ignore_public_acls      = var.s3[count.index]["ignore_public_acls"]
    # 새로운 Public bucket & access point 차단
    block_public_policy     = var.s3[count.index]["block_public_policy"]
    # 기존 Public bucket & access point 차단
    restrict_public_buckets = var.s3[count.index]["restrict_public_buckets"]
}

data "aws_s3_bucket" "policy-selected" {
    count = length(var.s3_bucket_policy)

    bucket = var.s3_bucket_policy[count.index]["name"]
}


resource "aws_s3_bucket_policy" "s3-bucket-policy-proj" {
    count = length(var.s3_bucket_policy)

    bucket = data.aws_s3_bucket.policy-selected[count.index].id
    policy = <<EOF
${var.s3_bucket_policy[count.index]["bucket_policy"]}
    EOF
}


resource "aws_s3_bucket_ownership_controls" "s3-ownership-controls-proj" {
    count = length(var.s3)

    bucket = aws_s3_bucket.s3-proj[count.index].id

    rule {
        object_ownership = var.s3[count.index]["object_ownership"]
    }
}

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
    count = length(var.s3)

    bucket = aws_s3_bucket.s3-proj[count.index].id

    rule {
        apply_server_side_encryption_by_default {
            kms_master_key_id = var.s3[count.index]["kms_id"]
            sse_algorithm     = var.s3[count.index]["sse_algorithm"]
        }
        bucket_key_enabled = true #var.s3[count.index]["bucket_key_enabled"]
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
/*
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

*/
