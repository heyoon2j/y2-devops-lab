#############################################################################################
/*
# VPN Configuration
1. VPN Gateway (AWS) (Target / in other module)
2. Customer Gateway 
3. Transit Gateway (Target / in other module)
4. Connection (in other module)
*/
#############################################################################################

locals {
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Customer Gateway (Target)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_customer_gateway" "main" {
    device_name = var.device_name
    type       = var.type
    bgp_asn    = var.bgp_asn
    ip_address = var.ip_address

    tags = merge(
        {
            Name = "${var.name}"
        },
        var.tags
    )
    # The ARN of a private certificate provisioned in AWS Certificate Manager (ACM).
    certificate_arn = var.certificate_arn
}
