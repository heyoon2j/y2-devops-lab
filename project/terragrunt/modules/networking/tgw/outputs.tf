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
