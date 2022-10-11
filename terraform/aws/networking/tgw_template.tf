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

resource "aws_ec2_transit_gateway" "tgw-proj" {
    description = "Transit Gateway"

    amazon_side_asn = 64512
    ## 연결된 교차 계정 연결을 자동으로 수락할지 여부
    # auto_accept_shared_attachments = ""

    # TGW에 Default Routing Table 할당
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    # DNS Support
    dns_support = "enable"
    # VPN ECMP Routing
    vpn_ecmp_support = "enable"

    tags = {
        Name = local.tgw["name"]
    }    
}


resource "aws_ec2_transit_gateway_route_table" "tgw-rt-y2net-prd-an2" {
    transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id

    tags = {
        Name = "tgw-y2net-prd-an2"
    }    
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attach-y2net-prd-an2" {
    subnet_ids         = ["${aws_subnet.sbn-y2net-prd-an2-a-pri.id}"]
    transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id # local.tgw["id"]
    vpc_id             = aws_vpc.vpc-y2net-prd-an2.id # local.vpc["id"]

    dns_support = "enable"
    ipv6_support = "disable"

    # VPC 연결이 EC2 Transit Gateway의 기본 라우팅 테이블과 연결되어야 하는지
    ## Association은 Routing Table과 Attachement를 연결하기 위해 사용 (Attachment는 하나의 Routing Table에만 연결 가능)
    transit_gateway_default_route_table_association = "false"
    ## Propagation은 Routing 정보를 전파하기 위해 사용 (Attachment는 다수의 Tating Table 연결 가능)
    transit_gateway_default_route_table_propagation = "false"

    tags = {
        Name = "tgw-attach-y2net-prd-an2"
    }    
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-assoc-y2net-prd-an2" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-y2net-prd-an2.id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prop-y2net-prd-an2" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-y2net-prd-an2.id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-rule0" {
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-y2net-prd-an2.id
}

/*
resource "aws_ec2_transit_gateway_route" "tgw-rt-rule" {
    destination_cidr_block         = "10.20.0.0/24"
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attch.id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id 
}
*/

