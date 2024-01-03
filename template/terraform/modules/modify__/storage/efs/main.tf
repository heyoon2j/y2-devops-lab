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
        transition_to_ia = var.efs[count.index]["lifecycle_transition_to_ia"] == null ? null : var.efs[count.index]["lifecycle_transition_to_ia"]
        transition_to_primary_storage_class = var.efs[count.index]["lifecycle_transition_to_primary_storage_class"] == null ? null : var.efs[count.index]["lifecycle_transition_to_primary_storage_class"]
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

    depends_on = [
        aws_efs_file_system.efs-proj  
    ]
}

resource "aws_efs_mount_target" "efs-net-proj" {
    count = length(var.efs_mount_target)

    file_system_id = data.aws_efs_file_system.mount-selected[count.index].id
    subnet_id      = data.aws_subnet.selected[count.index].id
    ip_address = var.efs_mount_target[count.index]["ip_address"]
    security_groups = var.efs_mount_target[count.index]["security_groups"]
}


data "aws_efs_file_system" "policy-selected" {
    count = length(var.efs_policy)    

    tags = {
        Name = var.efs_policy[count.index]["name"]
    }

    depends_on = [
        aws_efs_file_system.efs-proj  
    ]
}

resource "aws_efs_file_system_policy" "efs-policy-proj" {
    count = length(var.efs_policy)

    file_system_id = data.aws_efs_file_system.policy-selected[count.index].id

    bypass_policy_lockout_safety_check = true

    policy = <<POLICY
${var.efs_policy[count.index]["policy"]}
    POLICY

}

