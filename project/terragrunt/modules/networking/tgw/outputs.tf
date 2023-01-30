output "tgw" {
    description = "VPC Information"
    sensitive = true

    value = {
        id = aws_ec2_transit_gateway.tgw-proj.id
        name = "tgw-${var.proj_name}-${var.proj_env}-${var.proj_region}"
    }
}

output "attachment_vpc" {
    description = "Information for TGW"
    sensitive = true
    value = [
        for attachment in aws_ec2_transit_gateway_vpc_attachment.tgw-attach-vpc:
            {
                "id" = attachment.id
                "name" = attachment.tags_all["Name"]
            }
    ]
}


/*
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-assoc-proj" {
    count = length(local.association)
    for_each = local.association

    transit_gateway_route_table_id = local.association[count.index]. #aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
    transit_gateway_attachment_id  = local.association[count.index] #aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id


    association = [
        for rt in var.tgw_rt:{
            for assoc in rt.associationList:
                local.router[rt.name] => local.attachment[assoc]
        }
    ]
    propagation = [
        for rt in var.tgw_rt:{
            for propa in rt.propagationList:
                local.router[rt.name] => local.attachment[propa]
        }
    ]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prop-proj" {
    count = length(locals.propagation)

    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-y2net-prd-an2.id
}
*/
/*
resource "aws_ec2_transit_gateway_route" "tgw-rt-rule-proj" {
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach-proj.id
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-proj-xxx.id
    blackhole = var.blackhole
}*/

