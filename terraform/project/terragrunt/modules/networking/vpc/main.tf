/*
# VPC
1. VPC
    1) VPC 생성
    2) Subnet 생성
2. NAT Gateway
    1) EIP 생성
    2) NAT Gateway 생성
3. IGW Gateway
    1) IGW Gateway 생성
4. Routing
    1) Routing Table 생성
    2) Routing Table Association
    3) Routing Table의 Route 추가
*/


## Input Value



## Outpu Value


###########################################################
    locals {
        pub_rt_cnt = length(var.pub_rt)
        #pri_rt_cnt = length(var.pri_rt)
    }



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

resource "aws_vpc" "vpc-proj" {
    cidr_block = var.cidr_block

    #ipv6_cidr_block = var.vpc_v6cidr

    instance_tenancy = var.instance_tenancy # "default"

    enable_dns_hostnames = var.enable_dns_hostnames # true
    enable_dns_support = var.enable_dns_support # true

    # enable_classiclink = "false"
    # enable_classiclink_dns_support = "false"

    tags = {
        Name = "vpc-${var.proj_name}-${var.proj_env}-${var.proj_region}"
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

resource "aws_subnet" "sbn-proj-pub" {
    count = length(var.pub_subnet["subnet_name"])

    vpc_id = aws_vpc.vpc-proj.id
    cidr_block = var.pub_subnet["cidr_block"][count.index]
    availability_zone = var.pub_subnet["availability_zone"][count.index]
    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    assign_ipv6_address_on_creation = var.pub_subnet["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = var.pub_subnet["map_public_ip_on_launch"]

    tags = {
        Name = "sbn-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pub_subnet["subnet_name"][count.index]}"
    }
}

resource "aws_subnet" "sbn-proj-pri" {
    count = length(var.pri_subnet["subnet_name"])

    vpc_id = aws_vpc.vpc-proj.id
    cidr_block = var.pri_subnet["cidr_block"][count.index]
    availability_zone = var.pri_subnet["availability_zone"][count.index]
    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    assign_ipv6_address_on_creation = var.pri_subnet["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = var.pri_subnet["map_public_ip_on_launch"]

    tags = {
        Name = "sbn-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pri_subnet["subnet_name"][count.index]}"
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


resource "aws_route_table" "rt-proj-pub" {
    count = length(var.pub_rt)

    vpc_id = aws_vpc.vpc-proj.id
    #route = var.pub_rt[count.index]["route"]

    tags = {
        Name = "rt-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pub_rt[count.index]["rt_name"]}"
    }
    /*
    depends_on = [
        aws_internet_gateway.igw
    ]
    */
}

resource "aws_route_table_association" "rt-assoc-proj-pub" {
    count = length(var.pub_subnet["subnet_name"])
    subnet_id = aws_subnet.sbn-proj-pub[count.index].id

    route_table_id = aws_route_table.rt-proj-pub[local.pub_rt_cnt == 1 ? 0 : (count.index)/local.pub_rt_cnt].id
}

resource "aws_route" "rt-proj-pub-igw-conn" {
    route_table_id            = aws_route_table.rt-proj-pub[0].id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.igw-proj.id
    depends_on                = [aws_internet_gateway.igw-proj]
}
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





###################################################################
# Internet Gateway
resource "aws_internet_gateway" "igw-proj" {
    vpc_id = aws_vpc.vpc-proj.id

    tags = {
        Name = "igw-${var.proj_name}-${var.proj_region}"
    }
}

resource "aws_internet_gateway_attachment" "igw-attach-proj" {
    internet_gateway_id = aws_internet_gateway.igw-proj.id
    vpc_id = aws_vpc.vpc-proj.id
}
