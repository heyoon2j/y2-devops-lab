#############################################################################################
/*
# Security Group Configuration
1. Security Group
2. Ingress Rule
3. Egress Rule
*/
#############################################################################################
terraform {
    required_providers {
        # Terraform Alpha Version
        aws = {
            source  = "hashicorp/aws"
            version = "<= 5.7.0"
        }

    }
}


locals {
}


data "aws_vpc" "selected" {
    filter {
        name   = "tag:Name"
        values = [var.sg.vpc_name]
    }
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Security Group
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_security_group" "main" {
    name        = var.sg.name 
    description = var.sg.description 
    vpc_id      = data.aws_vpc.selected.id
    tags        = merge(
        var.sg.default_tags,
        {
            "Name"  = var.sg.name
        },
        var.sg.tags
    )
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Ingress Rule
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_vpc_security_group_ingress_rule" "main" {
    for_each = var.ingress

    security_group_id = aws_security_group.main.id

    from_port       = each.value.from_port
    to_port         = each.value.to_port
    ip_protocol     = each.value.protocol

    cidr_ipv4                       = each.value.cidr_ipv4
    prefix_list_id                  = each.value.prefix_list_id
    referenced_security_group_id    = each.value.referenced_security_group_id

    tags                        = each.value.tags
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Egress Rule
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_vpc_security_group_egress_rule" "main" {
    for_each = var.egress
    
    security_group_id = aws_security_group.main.id

    from_port       = each.value.from_port
    to_port         = each.value.to_port
    ip_protocol     = each.value.protocol

    cidr_ipv4                       = each.value.cidr_ipv4
    prefix_list_id                  = each.value.prefix_list_id
    referenced_security_group_id    = each.value.referenced_security_group_id

    tags                        = each.value.tags
}
