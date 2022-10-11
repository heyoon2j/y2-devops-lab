/*
# VPC
1. Virtual Private Gateway
    1) Transit Gateway 생성
    2) Transit Gateway의 Routing Table 생성
    3) Attachement 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장)
    4) Attachment를 Transit Gateway의 Routing Table에 Association
    5) Attachment를 Transit Gateway의 Routing Table에 Propagation
    6) Transit Gateway Routing 추가 작업
*/


## Input Value



## Outpu Value




############################################################
# 1. VPC
/*
'VPC Resource'

Args:
    cidr_block
        description = "VPC IPv4 CIDR"
        type = string
        validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    ipv6_cidr_block 
        description = "VPC IPv6 CIDR"
        type = string
        validation {}

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

*/


resource "aws_vpc" "vpc-propj" {
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
