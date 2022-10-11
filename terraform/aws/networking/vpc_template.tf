/*
# VPC
1. VPC
    1) VPC 생성
    2) Subnet 생성
2. NAT Gateway
    1) EIP 생성
    2) NAT Gateway 생성
    2) Routing Table의 Route 추가
3. IGW Gateway
    1) IGW Gateway 생성
    2) Routing Table의 Route 추가
4. Routing
    1) Routing Table 생성
    2) Routing Table의 Route 추가
    3) Routing Table Association
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


/*
'Subnet Resource'

Args:
    vpc_id
        description = " VPC ID"
        type = string
        validation {}

    cidr_block
        description = "Subnet IPv4 CIDR"
        type = string
        validation { 10.0.0.0/24, 172.16.30.0/26 ... }

    availability_zone
        description = "Subnet CIDR"
        type = string
        validation { 10.0.0.0/24, 172.16.30.0/26 ... }

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
    vpc_id = aws_vpc.vpc-proj.id
    cidr_block = 

    availability_zone = 

    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    assign_ipv6_address_on_creation = "false"    

    map_public_ip_on_launch = "true"

    tags = {
        Name : 
    }
}


resource "aws_subnet" "sbn-proj-pri" {
    vpc_id = aws_vpc.vpc-proj.id
    cidr_block = 

    availability_zone = 

    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    assign_ipv6_address_on_creation = "false"    

    map_public_ip_on_launch = "false"

    tags = {
        Name : 
    }
}


/*
'Routing Resource'

Args:
    vpc_id
        description = " VPC ID"
        type = string
        validation {}

    cidr_block
        description = "Subnet IPv4 CIDR"
        type = string
        validation { 10.0.0.0/24, 172.16.30.0/26 ... }

    availability_zone
        description = "Subnet CIDR"
        type = string
        validation { 10.0.0.0/24, 172.16.30.0/26 ... }

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












############################################################
# 2. NAT Gateway

resource "aws_eip" "eip-nat-y2net-prd-an2" {
    vpc = true
    tags = {
        Name = local.eipNat["name"]
    }
}

resource "aws_nat_gateway" "nat-y2net-prd-an2" {

    # EIP ID
    ## connectivity_type이 "public"인 경우에만 적용
    allocation_id = aws_eip.eip-nat-y2net-prd-an2.id # local.eipNat["id"]

    # 게이트웨이 유형
    ## "private" / "public" (Default)
    connectivity_type = "public"

    subnet_id = aws_subnet.sbn-y2net-prd-an2-a-pri.id # local.pubSub["id"]
    
    tags = {
        Name = local.ngw["name"]
    }    
}

############################################################
# 3. IGW Gateway

resource "aws_internet_gateway" "igw-proj" {
    vpc_id = aws_vpc.vpc-proj.id

    tags = {
        Name = 
    }
}

resource "aws_internet_gateway_attachment" "igw-attach-proj" {
    internet_gateway_id = aws_internet_gateway.igw-proj.id
    vpc_id = aws_vpc.vpc-proj.id
}



############################################################
# 4. Routing
resource "aws_route_table" "rt-y2net-prd-an2-a-pub" {
    vpc_id = aws_vpc.vpc-y2net-prd-an2.id # local.vpc_id

    tags = {
        Name = local.pubSubRT["name"]
    }
    /*
    depends_on = [
        aws_internet_gateway.igw
    ]
    */
}

## Association 할 때, 기본적으로 local에 대한 Routing은 자동으로 추가된다.
resource "aws_route_table_association" "rt-assoc-y2net-prd-an2-a-pub" {
    subnet_id = aws_subnet.sbn-y2net-prd-an2-a-pub.id # local.pubSub_id
    route_table_id = aws_route_table.rt-y2net-prd-an2-a-pub.id # local.pubSubRT_id
}

resource "aws_route" "rt-route-y2net-prd-an2-a-pub-igw" {
    route_table_id = aws_route_table.rt-y2net-prd-an2-a-pub.id # local.pubSubRT_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-y2net-prd-an2.id
}

resource "aws_route" "rt-route-y2net-prd-an2-a-pub-tgw-devVpc" {
    route_table_id = aws_route_table.rt-y2net-prd-an2-a-pub.id # local.pubSubRT_id
    destination_cidr_block = "10.20.10.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id
}

resource "aws_route" "rt-route-y2net-prd-an2-a-pub-tgw-prdVpc" {
    route_table_id = aws_route_table.rt-y2net-prd-an2-a-pub.id # local.pubSubRT_id
    destination_cidr_block = "10.20.20.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id
}


resource "aws_route_table" "rt-y2net-prd-an2-a-pri" {
    vpc_id = aws_vpc.vpc-y2net-prd-an2.id # local.vpc_id

    tags = {
        Name = local.priSubRT["name"]
    }
    /*
    depends_on = [
        aws_internet_gateway.igw
    ]
    */
}

## Association 할 때, 기본적으로 local에 대한 Routing은 자동으로 추가된다.
resource "aws_route_table_association" "rt-assoc-y2net-prd-an2-a-pri" {
    subnet_id = aws_subnet.sbn-y2net-prd-an2-a-pri.id # local.pubSub_id
    route_table_id = aws_route_table.rt-y2net-prd-an2-a-pri.id # local.pubSubRT_id
}

resource "aws_route" "rt-route-y2net-prd-an2-a-pri-nat" {
    route_table_id = aws_route_table.rt-y2net-prd-an2-a-pri.id # local.pubSubRT_id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-y2net-prd-an2.id
}











locals {
   ## VPC
    vpc = {
        name = "vpc-y2net-prd-an2"
        cidr = "10.20.0.0/24"
        # id = aws_vpc.vpc-y2net-prd-an2.id
    }

    ## Subnet
    pubSub = {
        name = "sbn-y2net-prd-an2-a-pub"
        cidr = "10.20.0.0/26"
        # id = aws_subnet.sbn-y2net-prd-an2-a-pub.id
    }

    priSub = {
        name = "sbn-y2net-prd-an2-a-pri"
        cidr = "10.20.0.64/26"
    }

    ## Gateway
    ## Internet Gateway
    igw = {
        name = "igw-y2net-prd-an2"
    }

    ## NAT Gateway
    ngw = {
        name = "nat-y2net-prd-an2"
    }

    ## Transit Gateway
    tgw = {
        name = "tgw-y2net-prd-an2"
        # id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id
    }

    ## EIP
    eipNat = {
        name = "eip-nat-y2net-prd-an2"
        # id = aws_eip.eip-nat-y2net-prd-an2.id
    }

    ## Routing Table
    pubSubRT = {
        name = "rt-y2net-prd-an2-a-pub"
        # id = aws_route_table.rt-y2net-prd-an2-a-pub.id
    }

    priSubRT = {
        name = "rt-y2net-prd-an2-a-pri"
    }
}



