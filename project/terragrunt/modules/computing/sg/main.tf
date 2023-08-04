resource "aws_security_group" "sg_main" {
    name        = var.sg.name 
    description = var.sg.description 
    vpc_id      = var.sg.vpc_id
    tags        = var.sg.tags
}


resource "aws_security_group_rule" "sg_main_ingress" {
    for_each = var.ingress

    security_group_id = aws_security_group.sg_main.id
    type = "ingress"

    from_port   = each.value.from_port
    to_port     = each.value.to_port
    protocol    = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
}


resource "aws_security_group_rule" "sg_main_egress" {
    for_each = var.egress
    
    security_group_id = aws_security_group.sg_main.id
    type = "egress"

    from_port   = each.value.from_port
    to_port     = each.value.to_port
    protocol    = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
}