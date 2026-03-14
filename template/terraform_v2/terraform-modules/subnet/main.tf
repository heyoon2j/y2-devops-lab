resource "aws_subnet" "this" {
  count = length(var.cidr_blocks)

  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_blocks[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-${count.index}"
  })
}

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