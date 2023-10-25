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


## Attachment
/*
'Transit Gateway Attachment Resource'

Args:
    transit_gateway_id
        description = "Transit Gateway ID"
        type = string
        validation {}

    vpc_id
        description = "VPC ID for attachment"
        type = string
        validation { vpc-012345abcdef }

    subnet_ids
        description = "Subnet ID for attachment interface"
        type = string
        validation { vpc-012345abcdef }

    dns_support = "enable"
        description = "DNS Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    ipv6_support = "disable"
        description = "DNS Support"
        type = string
        default = "disable"
        validation { "enable", "disable" (Default) }


    transit_gateway_default_route_table_association
        description = "default rout table associate to tgw"
        type = bool
        default = false
        validation { true (Default), false }

    transit_gateway_default_route_table_propagation
        description = "default rout table propagate to tgw"
        type = bool
        default = false
        validation { true (Default), false }
*/

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attach-proj" {

    transit_gateway_id = aws_ec2_transit_gateway.tgw-proj.id 
    vpc_id             = aws_vpc.vpc-proj.id
    # Attachment용 IP를 설정할 Subnet IDs(Multi-AZ)
    subnet_ids         = ["${aws_subnet.sbn-y2net-prd-an2-a-pri.id}"]

    dns_support = "enable"
    ipv6_support = "disable"

    # VPC 연결이 EC2 Transit Gateway의 기본 라우팅 테이블과 연결되어야 하는지
    ## Association은 Routing Table과 Attachement를 연결하기 위해 사용 (Attachment는 하나의 Routing Table에만 연결 가능)
    transit_gateway_default_route_table_association = "false"
    ## Propagation은 Routing 정보를 전파하기 위해 사용 (Attachment는 다수의 Tating Table 연결 가능)
    transit_gateway_default_route_table_propagation = "false"

    tags = {
        Name = ""
    }    
}



## Routing 작업
/*
'Transit Gateway Routing Resource'

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


resource "aws_ec2_transit_gateway_route_table" "tgw-rt-proj-xxx" {
    transit_gateway_id = aws_ec2_transit_gateway.tgw-proj.id

    tags = {
        Name = ""
    }    
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-assoc-proj" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prop-proj" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-rule-proj-01" {
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-proj.id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-rule-proj-02" {
    destination_cidr_block         = "172.13.0.0/24"
    blackhole = true
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
}
