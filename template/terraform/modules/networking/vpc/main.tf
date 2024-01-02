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
    # all_subnets = flatten([
    #     values({ public = aws_subnet.public }),
    #     values({ private_sbn = aws_subnet.private }),
    #     values({ database_sbn = aws_subnet.database })
    # ])
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
            "Name" = var.vpc_name
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
    assign_ipv6_address_on_creation = var.sbn_common_config["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = var.sbn_common_config["map_public_ip_on_launch"]

    tags = merge(
        {
            "Name" = join("", [var.sbn_common_config["naming_rule"], each.value["name"]])
        },
        var.sbn_common_config["tags"],
        each.value["tags"]
    )
}

resource "aws_subnet" "private" {
    for_each = var.sbn_pri

    vpc_id = aws_vpc.main.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["availability_zone"]
    assign_ipv6_address_on_creation = var.sbn_common_config["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = var.sbn_common_config["map_public_ip_on_launch"]
    
    tags = merge(
        {
            "Name" = join("", [var.sbn_common_config["naming_rule"], each.value["name"]])
        },
        var.sbn_common_config["tags"],
        each.value["tags"]
    )
}


data "aws_subnet" "tgw_attahment" {
    count = length(var.tgw_attachment_subnet)

    filter {
        name   = "tag:Name"
        values = [join("", [var.sbn_common_config["naming_rule"], var.tgw_attachment_subnet[count.index]])]
    }

    depends_on = [
        aws_subnet.public,
        aws_subnet.private
    ]
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_route_table" "public" {
    for_each = var.rt_pub

    vpc_id = aws_vpc.main.id
    tags = merge(
        {
            "Name" = join("", [var.rt_common_config["naming_rule"], each.value["name"]])
        },
        var.rt_common_config["tags"],
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
            "Name" = join("", [var.rt_common_config["naming_rule"], each.value["name"]])
        },
        var.rt_common_config["tags"],
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
    count = var.igw_name != null ? 1 : 0

    vpc_id = aws_vpc.main.id

    tags = merge(
        {
            "Name" = var.igw_name
        },
        var.igw_tags
    )
}