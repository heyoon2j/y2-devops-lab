#############################################################################################
/*
# Route53 Zone
1. Hosted Zone 생성
2. VPC Association

3. Zone File 생성 (수동으로 설정)
*/
#############################################################################################

locals {

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Hosted Zone
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_route53_zone" "main" {
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
        values = [each.value]
    }
}

