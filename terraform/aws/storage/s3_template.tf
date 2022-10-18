/*
# S3
1. S3
    1) Bucket 생성
    2) ACL 설정
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
    bucket = "my-tf-test-bucket"
        description = "Description"
        type = string
        default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    amazon_side_asn
        description = "AWS ASN"
        type = number
        default = 64512
        validation { 64512 ~ 65534, 4200000000 ~ 4294967294 }

    auto_accept_shared_attachments
        description = "auto acception about shared account"
        type = string
        default = "disable"
        validation { "disable" (Default), "enable" }

    default_route_table_association 
        description = "default rout table associate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    default_route_table_propagation
        description = "default rout table propagate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    dns_support
        description = "DNS Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    vpn_ecmp_support
        description = "VPN ECMP Routing Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    multicast_support
        description = "Multicast Support"
        type = string
        default = "disable"
        validation { "enable", "disable" (Disable) }
*/

resource "aws_s3_bucket" "s3-proj-temp" {
    bucket = "my-tf-test-bucket"
    #object_lock_enabled = false

    tags = {
        Name        = "My bucket"
        Environment = "Dev"
    }
}



/*
'S3 Bucket ACL Resource'

Args:
    bucket = "my-tf-test-bucket"
        description = "Description"
        type = string
        default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    amazon_side_asn
        description = "AWS ASN"
        type = number
        default = 64512
        validation { 64512 ~ 65534, 4200000000 ~ 4294967294 }

    auto_accept_shared_attachments
        description = "auto acception about shared account"
        type = string
        default = "disable"
        validation { "disable" (Default), "enable" }
*/

resource "aws_s3_bucket_acl" "s3-acl-proj-temp" {
  bucket = aws_s3_bucket.s3-proj-temp.id
  acl    = "private"
}


/*
'S3 Bucket Resource'

Args:
    bucket = "my-tf-test-bucket"
        description = "Description"
        type = string
        default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    amazon_side_asn
        description = "AWS ASN"
        type = number
        default = 64512
        validation { 64512 ~ 65534, 4200000000 ~ 4294967294 }

    auto_accept_shared_attachments
        description = "auto acception about shared account"
        type = string
        default = "disable"
        validation { "disable" (Default), "enable" }

    default_route_table_association 
        description = "default rout table associate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    default_route_table_propagation
        description = "default rout table propagate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    dns_support
        description = "DNS Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    vpn_ecmp_support
        description = "VPN ECMP Routing Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    multicast_support
        description = "Multicast Support"
        type = string
        default = "disable"
        validation { "enable", "disable" (Disable) }
*/



resource "aws_s3_bucket_server_side_encryption_configuration" "s3-encrypt-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id

    rule {
        apply_server_side_encryption_by_default {
            kms_master_key_id = aws_kms_key.mykey.arn
            sse_algorithm     = "aws:kms"
        }
    }
}


/*
'S3 Bucket Resource'

Args:
    bucket = "my-tf-test-bucket"
        description = "Description"
        type = string
        default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    amazon_side_asn
        description = "AWS ASN"
        type = number
        default = 64512
        validation { 64512 ~ 65534, 4200000000 ~ 4294967294 }

    auto_accept_shared_attachments
        description = "auto acception about shared account"
        type = string
        default = "disable"
        validation { "disable" (Default), "enable" }

    default_route_table_association 
        description = "default rout table associate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    default_route_table_propagation
        description = "default rout table propagate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

*/

resource "aws_s3_bucket_lifecycle_configuration" "s3-lifecycle-proj-temp" {
    bucket = aws_s3_bucket.s3-proj-temp.id

    rule {
        id = "rule-1"

        filter {}

        # ... other transition/expiration actions ...

        status = "Enabled"
    }
}