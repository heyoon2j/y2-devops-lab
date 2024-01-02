# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Transit Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "tgw_id" {
    description = "TGW ID"
    sensitive = true

    value = aws_ec2_transit_gateway.main.id
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Attachment for routing
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "attachment_vpc" {
    description = "Information for attachment VPC"
    sensitive = false
    value = tomap({
        for k, g in aws_ec2_transit_gateway_vpc_attachment.this : k => g.id
    })
    
    # [
    #     for attachment in aws_ec2_transit_gateway_vpc_attachment.tgw_attach_vpc:
    #         {
    #             "id" = attachment.id
    #             "name" = attachment.tags_all["Name"]
    #         }
    # ]
}

output "attahment_vpn" {
    description = "Information for attachment VPN"
    value = null
    # value = tomap({
    #     for k, g in aws_ec2_transit_gateway_vpc_attachment.this : k => g.id
    # })
}

output "attachment_dx" {
    description = "Information for attachment DX"
    value = null
    # value = tomap({
    #     for k, g in aws_ec2_transit_gateway_vpc_attachment.this : k => g.id
    # })
}

output "attachment_peering" {
    description = "Information for attachment TGW Peering"
    value = tomap({
        for k, g in aws_ec2_transit_gateway_peering_attachment.this : k => g.id
    })
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "tgw_rt" {
    description = "Information for attachment TGW Peering"
    sensitive = false

    value = tomap({
        for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id
    }) 
}