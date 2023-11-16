output "tgw" {
    description = "VPC Information"
    sensitive = true

    value = {
        id = aws_ec2_transit_gateway.tgw_proj.id
        name = "${var.tgw_name}"
    }
}

output "attachment_vpc" {
    description = "Information for TGW"
    sensitive = false
    value = tomap({
        for k, g in aws_ec2_transit_gateway_vpc_attachment.tgw_attach_vpc : k => g.id
    })
    
    # [
    #     for attachment in aws_ec2_transit_gateway_vpc_attachment.tgw_attach_vpc:
    #         {
    #             "id" = attachment.id
    #             "name" = attachment.tags_all["Name"]
    #         }
    # ]
}
