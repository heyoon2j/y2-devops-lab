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
resource "aws_efs_file_system" "efs-proj-temp" {
    creation_token = "my-product"

    encrypted = true
    kms_key_id = ""

    availability_zone_name = ""

    lifecycle_policy {
        transition_to_ia = "AFTER_30_DAYS"
        transition_to_primary_storage_class = "AFTER_1_ACCESS"
    }

    performance_mode = "generalPurpose"
    throughput_mode = "bursting"

    # throughput_mode = "provisioned"인 경우에만 사용 가능
    #provisioned_throughput_in_mibps = 

    tags = {
        Name = "main"
    }

}

resource "aws_efs_backup_policy" "efs-bak-proj-temp" {
    file_system_id = aws_efs_file_system.efs-proj-temp.id

    backup_policy {
        status = "DISABLED"
    }
}


resource "aws_efs_mount_target" "efs-net-proj-temp" {
    file_system_id = aws_efs_file_system.efs-proj-temp.id
    subnet_id      = aws_subnet.alpha.id
    ip_address = 
    security_groups = 
}

/*
resource "aws_efs_file_system_policy" "efs-policy-proj-temp" {
    file_system_id = aws_efs_file_system.efs-proj-temp.id

    bypass_policy_lockout_safety_check = true

    policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Id": "ExamplePolicy01",
        "Statement": [
            {
                "Sid": "ExampleStatement01",
                "Effect": "Allow",
                "Principal": {
                    "AWS": "*"
                },
                "Resource": "${aws_efs_file_system.efs-proj-temp.arn}",
                "Action": [
                    "elasticfilesystem:ClientMount",
                    "elasticfilesystem:ClientWrite"
                ],
                "Condition": {
                    "Bool": {
                        "aws:SecureTransport": "true"
                    }
                }
            }
        ]
    }
    POLICY
}
*/