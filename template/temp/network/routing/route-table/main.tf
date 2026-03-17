resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}