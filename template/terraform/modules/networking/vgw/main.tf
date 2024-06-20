#############################################################################################
/*
# VPN Configuration
1. VPN Gateway (AWS)
2. Custom Gateway (Target / in other module)
3. Transit Gateway (Target / in other module)
4. Connection (in other module)
*/
#############################################################################################

locals {
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. VPN Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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
