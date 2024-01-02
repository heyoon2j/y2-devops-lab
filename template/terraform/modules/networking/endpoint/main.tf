#############################################################################################
/*
# Endpoint Configuration
1. VPC Endpoint

*/
#############################################################################################

locals {

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. VPC Endpoint
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_vpc_endpoint" "this" {
    for_each = var.endpoint
    
    service_name = each.value.service_name
    vpc_endpoint_type = each.value.vpc_endpoint_type

    vpc_id       = each.value.vpc_id
    subnet_ids   = each.value.subnet_ids
    security_group_ids = each.value.security_group_ids
    route_table_ids    = each.value.route_table_ids

    tags = each.value.tags
}