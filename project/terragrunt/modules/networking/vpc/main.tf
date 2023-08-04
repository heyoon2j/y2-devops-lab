/*
# VPC
1. VPC
    1) VPC 생성
    2) Subnet 생성
2. Routing
    1) Routing Table 생성
    2) Routing Table Association
    3) Routing Table의 Route 추가
3. NAT Gateway
    1) EIP 생성
    2) NAT Gateway 생성
4. IGW Gateway
    1) IGW Gateway 생성
5. TGW Attachment
    1) Attachment에서 사용할 정보 전달
*/


## Input Value



## Outpu Value


###########################################################
/*abcd
locals {
    pub_rt_cnt = var.pub_rt != 0 ? length(var.pub_rt) : 0
    pri_rt_cnt = var.pri_rt != 0 ? length(var.pri_rt) : 0
    azs_cnt = var.use_azs != null ? length(var.use_azs) : 1
}
abcd*/



############################################################
# 1. VPC
/*
'VPC Resource'

Args:
    cidr_block
        description = "VPC IPv4 CIDR"
        type = string
        validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    instance_tenancy
        description = "VPC에서 생성하는 인스턴스의 테넌시 기본 설정"
        type = string
        default = "default"
        validation { "default"(Default), "dedicated" }

    enable_dns_support
        description = "VPC에서 DNS 지원을 활성화/비활성화"
        type = bool
        default = true
        validation { true (Default), false }
    
    enable_dns_hostnames
        description = "Public IP Address에 Hostname을 받을지에 대한 여부"
        type = bool
        default = false
        validation { true, false (Default) }

*/

resource "aws_vpc" "vpc_main" {
    cidr_block = var.cidr_block

    instance_tenancy = var.instance_tenancy # "default"

    enable_dns_hostnames = var.enable_dns_hostnames # true
    enable_dns_support = var.enable_dns_support # true

    enable_network_address_usage_metrics = var.enable_network_address_usage_metrics
    # enable_classiclink = "false"
    # enable_classiclink_dns_support = "false"

    tags = {
        Name = "${var.vpc_name}"
    }
}

/*
'Subnet Resource'

Args:
    subnet_name
        description = "Sunbet Name"
        type = string
        validation

    vpc_id
        description = "VPC ID"
        type = string
        validation {}

    cidr_block
        description = "Subnet IPv4 CIDR"
        type = string
        validation { 10.0.0.0/24, 172.16.30.0/26 ... }

    availability_zone
        description = "Availablity Zone"
        type = string
        validation { ap-northeast-2a, ap-northeast-2c ... }

    private_dns_hostname_type_on_launch
        description = "Private Hostname FQDN 지정 시, 들어갈 내용 선택"
        type = string
        validation { ip-name, resource-name }

    ipv6_cidr_block
        description = "Subnet IPv6 CIDR"
        type = string
        validation { ... }

    assign_ipv6_address_on_creation
        description = "Use IPv6 address or not "
        type = bool
        validation { true, false (Default) }

    map_public_ip_on_launch
        description = "해당 Subnet에서 인스턴스 시작 시, Public IP 할당할지 여부"
        type = bool
        validation { true, false (Default) }
*/

resource "aws_subnet" "sbn_pub" {
    for_each = var.subnet_pub

    vpc_id = aws_vpc.vpc_main.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["availability_zone"]
    assign_ipv6_address_on_creation = each.value["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

    tags = {
        Name = "${each.value.name}"
    }
}

resource "aws_subnet" "sbn_pri" {
    for_each = var.subnet_pri

    vpc_id = aws_vpc.vpc_main.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["availability_zone"]
    assign_ipv6_address_on_creation = each.value["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

    tags = {
        Name = "${each.value.name}"
    }
}



##########################################################
# Routing Table

/*
'Routing Resource'

Args:

    vpc_id
        description = " VPC ID"
        type = string
        validation {}

*/

/*
    route = [
        {
           cidr_block = "10.0.1.0/24"
           gateway_id = aws_internet_gateway.example.id
        }
        {
           cidr_block = "10.0.1.0/24"
           transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id        
        }
    ]
*/
## Association 할 때, 기본적으로 local에 대한 Routing은 자동으로 추가된다.

resource "aws_route_table" "rt_pub" {
    for_each = var.rt_pub

    vpc_id = aws_vpc.vpc_main.id
    #route = []

    tags = {
        Name = each.value["name"]
    }
}
resource "aws_route_table_association" "rt_pub_assoc" {
    for_each = var.rt_pub_assoc

    route_table_id = aws_route_table.rt_pub[each.value].id
    subnet_id = aws_subnet.sbn_pub[each.key].id
}


#### Private Routing Table
resource "aws_route_table" "rt_pri" {
    for_each = var.rt_pri

    vpc_id = aws_vpc.vpc_main.id
    #route = []

    tags = {
        Name = each.value["name"]
    }
}
resource "aws_route_table_association" "rt_pri_assoc" {
    for_each = var.rt_pri_assoc

    route_table_id = aws_route_table.rt_pri[each.value].id
    subnet_id = aws_subnet.sbn_pri[each.key].id
}


###################################################################
# Internet Gateway

resource "aws_internet_gateway" "igw_main" {
    count = var.internet_gateway != null ? 1 : 0

    vpc_id = aws_vpc.vpc_main.id

    tags = {
        Name = "${var.internet_gateway["name"]}"
    }
}
/*
resource "aws_internet_gateway_attachment" "igw_attach" {
    count = var.internet_gateway != null ? 1 : 0

    internet_gateway_id = aws_internet_gateway.igw_main[0].id 
    vpc_id = aws_vpc.vpc_main.id

    depends_on = [aws_internet_gateway.igw_main]
}
*/
/*
data "aws_route_tables" "rts_igw" {
    vpc_id = aws_vpc.vpc_main.id

    filter {
        name = "tag:attach_igw"
        values = ["true", "True"]
    }
}
*/

resource "aws_route" "rt_pub_igw_conn" {
    for_each = var.rt_pub

    route_table_id = aws_route_table.rt_pub[each.key].id

    destination_cidr_block    = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.igw_main[0].id

    depends_on  = [aws_internet_gateway.igw_main, aws_route_table.rt_pub]
}



############################################

data "aws_subnet" "tgw_attahment" {
    count = length(var.tgw_attachment_subnet)
    filter {
        name   = "tag:Name"
        values = [var.tgw_attachment_subnet[count.index]]
    }

    depends_on = [
        aws_subnet.sbn_pub,
        aws_subnet.sbn_pri
    ]
}
