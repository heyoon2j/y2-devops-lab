#############################################################################################
/*
# Subnet Configuration
1. Subnet
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


data "aws_vpc" "selected" {
    filter {
        name   = "tag:Name"
        values = [var.sg.vpc_name]
    }
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_subnet" "this" {
    for_each = var.sbn

    vpc_id = data.aws_vpc.selected.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["availability_zone"]
    assign_ipv6_address_on_creation = each.value["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

    tags = merge(
        each.value.default_tags,
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )
}
/*
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
*/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_route_table" "this" {
    for_each = var.rt

    vpc_id = data.aws_vpc.selected
    tags = merge(
        each.value.default_tags,
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )
}


resource "aws_route_table_association" "this" {
    for_each = var.sbn

    route_table_id = aws_route_table.this[each.value["route_table"]].id
    subnet_id = aws_subnet.this[each.key].id
}



/*
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
*/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 4. Internet Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_internet_gateway" "this" {
    count = var.igw.name != null ? 1 : 0

    vpc_id = data.aws_vpc.selected

    tags = merge(
        var.igw.default_tags,
        {
            "Name" = var.igw_name
        },
        var.igw.tags
    )
}
