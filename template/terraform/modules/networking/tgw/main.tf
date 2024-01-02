#############################################################################################
/*
# Transit Gateway Configuration
1. Transit Gateway 생성
2. Attachement 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장) / VPC, DX, VPN, TGW Peering
    - VPC Attachment
    - DX Attachment
    - VPN Attachment
    - TGW Peering Attachment
3. Attachment를 Transit Gateway의 Routing Table에 Association
4. Attachment를 Transit Gateway의 Routing Table에 Propagation
5. Transit Gateway의 Routing Table 생성
6. Transit Gateway Routing 추가 작업
*/
#############################################################################################

locals {
    # attachment = merge(
    #     {for attach in aws_ec2_transit_gateway_vpc_attachment.tgw-attach-vpc : attach.tags_all["Name"] => attach.vpc_id}
    #     ,{for attach in aws_ec2_transit_gateway_peering_attachment.tgw-attach-peering : attach.tags_all["Name"] => attach.peering_id}
    #     #,{for attach in peering}
    #     #,{for attach in peering}
    # )
    # router = {for rt in aws_ec2_transit_gateway_route_table.tgw-rt-proj : rt.tags_all["Name"] => rt.id}
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Transit Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_ec2_transit_gateway" "main" {
    amazon_side_asn = var.amazon_side_asn

    ## 연결된 교차 계정 연결을 자동으로 수락할지 여부
    auto_accept_shared_attachments = var.auto_accept_shared_attachments

    # TGW에 Default Routing Table 할당
    default_route_table_association = var.default_route_table_propagation 
    default_route_table_propagation = var.default_route_table_propagation

    # DNS Support
    dns_support = var.dns_support
    # VPN ECMP Routing
    vpn_ecmp_support = var.vpn_ecmp_support
    # Multicast Support
    multicast_support = var.multicast_support

    tags = merge(
        {
            "Name" = var.tgw_name
        },
        var.tags
    )
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (VPC)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
    for_each = var.attachment_vpc

    transit_gateway_id = aws_ec2_transit_gateway.main.id 
    vpc_id             = each.value["vpc_id"]
    # Attachment용 IP를 설정할 Subnet IDs(Multi-AZ)
    subnet_ids         = each.value["subnet_ids"]

    dns_support = "enable"
    ipv6_support = "disable"

    # VPC 연결이 EC2 Transit Gateway의 기본 라우팅 테이블과 연결되어야 하는지
    ## Association은 Routing Table과 Attachement를 연결하기 위해 사용 (Attachment는 하나의 Routing Table에만 연결 가능)
    transit_gateway_default_route_table_association = "false"
    ## Propagation은 Routing 정보를 전파하기 위해 사용 (Attachment는 다수의 Tating Table 연결 가능)
    transit_gateway_default_route_table_propagation = "false"

    tags = merge(
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )  
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (VPN)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (DX)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (TGW Peering)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_ec2_transit_gateway_peering_attachment" "this" {
    for_each = var.attachment_peering

    transit_gateway_id      = aws_ec2_transit_gateway.main.id
    peer_account_id         = each.value["peer_account_id"]
    peer_region             = each.value["peer_region"]
    peer_transit_gateway_id = each.value["peer_transit_gateway_id"]

    tags = merge(
        {
            "Name" = each.value["name"]
        },
        each.value["tags"]
    )  
}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_ec2_transit_gateway_route_table" "this" {
    for_each = var.tgw_rt
    
    transit_gateway_id = aws_ec2_transit_gateway.main.id

    tags = merge(
        {
            Name = each.value["name"]
        },
        each.value["tags"]
    )
}
