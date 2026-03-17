resource "aws_subnet" "this" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr
  ipv6_cidr_block         = var.ipv6_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}
