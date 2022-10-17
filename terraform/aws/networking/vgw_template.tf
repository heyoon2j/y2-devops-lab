/*
# VPN Gateway
1. VPN Gateway
    1) Customer Gateway 생성
    2) Virtual Private Gateway 생성
    3) VPN Attachment 생성
    4) VPN Connection 생성 (사이트 확인 : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection)
    5) Routing 추가 (VPC or TGW Routing Table)
    6) VPN Propagation 생성 (VPC 연결인 경우)
*/


## Input Value



## Outpu Value




############################################################
# 1. VPN Gateway
/*
'Customer Gateway Resource'

Args:
    device_name
        description = "Customer gateway device's name"
        type = string
        validation { }

    bgp_asn
        description = "Customer gateway device's BGP ASN"
        type = number
        validation { 1 ~ 2147483647 }

    ip_address
        description = "Customer gateway device's outside interface"
        type = string
        validation { "10.0.0.5", "172.16.30.12" ... }

    type
        description = "The type of customer gateway"
        type = string
        default = "ipsec.1"
        validation { "ipsec.1" (Only) }

*/

resource "aws_customer_gateway" "cgw-proj" {
    device_name = "cgw-proj"

    # Customer Information
    bgp_asn    = 65000
    ip_address = "172.83.124.10"
    type       = "ipsec.1"

    tags = {
        Name = "main-customer-gateway"
    }
}


/*
'Customer Gateway Resource'

Args:
    vpc_id
        description = "VPC ID"
        type = string
        validation { }
 
    amazon_side_asn
        description = "Amazon side ASN"
        type = number
        validation { 64512 ~ 65534, 4200000000 ~ 4294967294 }  

*/

resource "aws_vpn_gateway" "vgw-proj" {
    vpc_id = aws_vpc.main.id
    amazon_side_asn = 64512

    tags = {
        Name = "main"
    }
}

resource "aws_vpn_gateway_attachment" "vpn_attach-proj" {
    vpc_id         = aws_vpc.network.id
    vpn_gateway_id = aws_vpn_gateway.vgw-proj.id
}


