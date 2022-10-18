/*
# Transit Gateway
1. Transit Gateway
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
# 1. Transit Gateway
/*
'Transit Gateway Resource'

Args:
    description
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

resource "aws_ec2_transit_gateway" "tgw-proj" {
    description = "Transit Gateway"

    amazon_side_asn = 64512
    ## 연결된 교차 계정 연결을 자동으로 수락할지 여부
    auto_accept_shared_attachments = "disable"

    # TGW에 Default Routing Table 할당
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    # DNS Support
    dns_support = "enable"
    # VPN ECMP Routing
    vpn_ecmp_support = "enable"
    # Multicast Support
    multicast_support = "disable"

    tags = {
        Name = ""
    }    
}