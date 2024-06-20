#############################################################################################
/*
# VPN Configuration
1) VGW --- CGW
2) TGW --- CGW
*/
#############################################################################################

locals {
}



resource "aws_vpn_gateway" "main" {
    vpc_id = var.vpc_id
    amazon_side_asn = var.amazon_side_asn
    tags = merge(
        {
            Name = "${var.name}"
        },
        var.tags
    )
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. VGW --- CGW
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_vpn_connection" "example" {
    customer_gateway_id = aws_customer_gateway.example.id
    transit_gateway_id  = aws_ec2_transit_gateway.example.id
    type                = aws_customer_gateway.example.type
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. VGW --- CGW
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_vpn_connection" "main" {
    vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
    customer_gateway_id = aws_customer_gateway.customer_gateway.id
    type                = "ipsec.1"
    static_routes_only  = true
}