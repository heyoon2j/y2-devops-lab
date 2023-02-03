/*
# Elastic File System
1. EFS
    1) EFS 생성
    2) Backup 설정
    3) Network 설정
    4) Policy 설정 (필요시 설정, 기본은 IAM으로)
*/


## Input Value



## Outpu Value




############################################################
# 1. EFS
/*
'EFS Resource'

Args:
    creation_token
        description = "EFS Name"
        type = string
        #default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    encrypted
        description = "Whether to encrypt or notWhether "
        type = bool
        default = true
        validation { true (Default), false }

    kms_key_id
        description = "KMS Key for encryption"
        type = string
        validation { "^arn:*" }


    availability_zone_name

    transition_to_ia
        description = "EFS Lifecycle Policy: move to ia storage from primary"
        type = string
        default = "AFTER_30_DAYS"
        validation { "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS" }
    
    transition_to_primary_storage_class
        description = "EFS Lifecycle Policy: move to primary from ia storage"
        type = string
        default = "AFTER_1_ACCESS"
        validation { "AFTER_1_ACCESS" }

    performance_mode
        description = "EFS IOPS Mode" 
        type = string
        default = "generalPurpose"
        validation { "generalPurpose" (Default), "maxIO" }

    throughput_mode
        description = "EFS Throughput Mode" 
        type = string
        default = "bursting"
        validation { "bursting", "provisioned" }

    status
        description = "Whether use backup policy or not" 
        type = string
        default = "DISABLED"
        validation { "ENABLED" (Default), "DISABLED" }

    ip_address
    security_groups


*/
resource "aws_efs_file_system" "efs-proj" {
    count = length(var.efs)

    creation_token = var.efs[count.index]["creation_token"]

    encrypted = var.efs[count.index]["encrypted"]
    kms_key_id = var.efs[count.index]["kms_key_id"]

    availability_zone_name = var.efs[count.index]["availability_zone_name"]

    lifecycle_policy {
        transition_to_ia = var.efs[count.index]["lifecycle_transition_to_ia"]
        transition_to_primary_storage_class = var.efs[count.index]["lifecycle_transition_to_primary_storage_class"]
    }

    performance_mode = var.efs[count.index]["performance_mode"]
    throughput_mode = var.efs[count.index]["throughput_mode"]

    # throughput_mode = "provisioned"인 경우에만 사용 가능
    provisioned_throughput_in_mibps = var.efs[count.index]["provisioned_throughput_in_mibps"]

    tags = var.efs[count.index]["tags"]

}


resource "aws_efs_backup_policy" "efs-bak-proj" {
    count = length(var.efs)

    file_system_id = aws_efs_file_system.efs-proj[count.index].id

    backup_policy {
        status = var.efs[count.index]["use_autoBackup"]
    }
}


data "aws_subnet" "selected" {
    count = length(var.efs_mount_target)

    filter {
        name   = "tag:Name"
        values = ["${var.efs_mount_target[count.index]["subnet_name"]}"]
    }
}

data "aws_efs_file_system" "mount-selected" {
    count = length(var.efs_mount_target)  

    tags = {
        Name = var.efs_mount_target[count.index]["efs_name"]
    }
}

resource "aws_efs_mount_target" "efs-net-proj" {
    count = length(var.efs_mount_target)

    file_system_id = data.aws_efs_file_system.mount-selected.id
    subnet_id      = data.aws_subnet.selected["selected"].id
    ip_address = var.efs_mount_target[count.index]
    security_groups = var.efs_mount_target[count.index]
}


data "aws_efs_file_system" "policy-selected" {
    count = length(var.efs_policy)    

    tags = {
        Name = var.efs_policy[count.index]["name"]
    }
}

resource "aws_efs_file_system_policy" "efs-policy-proj" {
    count = length(var.efs_policy)

    file_system_id = data.aws_efs_file_system.policy-selected.id

    bypass_policy_lockout_safety_check = true

    policy = <<POLICY
${var.efs_policy[count.index]["policy"]}
    POLICY
}







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
