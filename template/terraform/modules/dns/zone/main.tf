/*
# Route53 Zone
1. Hostted Zone 생성
2. VPC Association
3. Zone File 생성 (수동으로 설정)
4. 
*/


## Input Value



## Outpu Value


###########################################################
/*
locals {
    pub_rt_cnt = var.pub_rt != 0 ? length(var.pub_rt) : 0
    pri_rt_cnt = var.pri_rt != 0 ? length(var.pri_rt) : 0
    azs_cnt = var.use_azs != null ? length(var.use_azs) : 1
}
*/


############################################################
# 1. Hoszed Zone
/*
'VPC Resource'

Args:
    variable "domina" {
        description = "Hosted Zone"
        type = string
    }

    variable "tags" {
        description = "Tags"
        type = optional(map(any))
    }
*/


resource "aws_route53_zone" "hosted_zone" {
    name = var.domain
    comment = var.comment

    force_destroy = var.force_destroy

    dynamic "vpc" {
        for_each = data.aws_vpc.selected

        content {
            vpc_id = vpc.value.id
        }
    }

    tags = var.tags
}


data "aws_vpc" "selected" {
    for_each = var.private_vpc

    filter {
        name   = "tag:Name"
        values = [each.value["name"]]
    }
}

