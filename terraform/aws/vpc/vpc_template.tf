/*
# VPC
1. Create VPC
2. Create Subnet
3. Create Routing
4. Create VGW
5. Create TGW
*/


## Input Value



## Outpu Value




############################################################
# 1. Create a VPC
/*
'VPC Resource'

Args:
    cidr_block
        description = "VPC CIDR"
        type = string
        validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    instance_tenancy
        description = "VPC에서 생성하는 인스턴스의 테넌시 기본 설정"
        type = string
        validation { "default"(Default), "dedicated" }

    enable_dns_support
        description = "VPC에서 DNS 지원을 활성화/비활성화"
        type = bool
        validation { true (Default), false }
    
    enable_dns_hostnames
        description = "Public IP Address에 Hostname을 받을지에 대한 여부"
        type = bool
        validation { true, false (Default) }

    ipv6_cidr_block 
        description = ""
        type = string
        validation {}
*/


resource "aws_vpc" "vpc-proj" {

    cidr_block = var.vpc_cidr

    #ipv6_cidr_block = var.vpc_v6cidr

    instance_tenancy = "default"

    enable_dns_hostnames = "true"
    enable_dns_support = "true"

    # enable_classiclink = "false"
    # enable_classiclink_dns_support = "false"

    tags = {
        Name = var.vpc_name
    }
}



############################################################
# 2. Create Subnet

############################################################
# 3. Create Routing

############################################################
# 4. Create VGW

############################################################
# 5. Create TGW