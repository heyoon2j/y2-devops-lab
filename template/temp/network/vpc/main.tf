#############################################################################################
/*
# VPC Configuration
1. VPC
2. Route Table
3. Subnet
4. IGW Gateway

5. NAT Gateway (in other module)
6. TGW Attachment (in other module)
7. Route (in other module)
*/
#############################################################################################

locals {
}

terraform {
    required_providers {
        # Terraform Alpha Version
        aws = {
            source  = "hashicorp/aws"
            version = "<= 5.7.0"
        }
    }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. VPC
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_vpc" "main" {

    cidr_block = var.cidr_block
    enable_dns_hostnames = var.enable_dns_hostnames # true
    enable_dns_support = var.enable_dns_support # true

    instance_tenancy = var.instance_tenancy # "default"

    enable_network_address_usage_metrics = var.enable_network_address_usage_metrics
    # enable_classiclink = "false"
    # enable_classiclink_dns_support = "false"

    tags = merge(
        {
            "Name" = var.name
        },
        var.tags
    )
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_subnet" "public" {
    for_each = var.sbn_pub

    vpc_id = aws_vpc.main.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["availability_zone"]
    assign_ipv6_address_on_creation = each.value["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

    tags = merge(
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )
}

resource "aws_subnet" "private" {
    for_each = var.sbn_pri

    vpc_id = aws_vpc.main.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["availability_zone"]
    assign_ipv6_address_on_creation = each.value["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

    tags = merge(
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_route_table" "public" {
    for_each = var.rt_pub

    vpc_id = aws_vpc.main.id
    tags = merge(
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )
}


resource "aws_route_table_association" "public" {
    for_each = var.sbn_pub

    route_table_id = aws_route_table.public[each.value["route_table"]].id
    subnet_id = aws_subnet.public[each.key].id
}


resource "aws_route_table" "private" {
    for_each = var.rt_pri

    vpc_id = aws_vpc.main.id
    tags = merge(
        {
            "Name" = each.value.name #join("", [var.rt_common_config["naming_rule"], each.value["name"]])
        },
        each.value["tags"]
    )
}

resource "aws_route_table_association" "private" {
    for_each = var.sbn_pri

    route_table_id = aws_route_table.private[each.value["route_table"]].id
    subnet_id = aws_subnet.private[each.key].id
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 4. Internet Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_internet_gateway" "this" {
    count = var.igw.name != null ? 1 : 0

    vpc_id = aws_vpc.main.id

    tags = merge(
        {
            "Name" = var.igw.name
        },
        var.igw.tags
    )
}
 
resource "aws_route" "igw" {
    for_each = aws_route_table.public

    route_table_id  = each.value.id
    gateway_id      = aws_internet_gateway.this
}