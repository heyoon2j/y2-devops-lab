# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "vpc_id" {
    description = "VPC ID"
    type = string
}

variable "sbn_pri" {
    description = "Private Subnet"
    type = map(string)
}

variable "sbn_pub" {
    description = "Public Subnet"
    type = map(string)
}

variable "rt_pub" {
    description = "Public Subnet Dictionary Value"
    type = map(string)
}

variable "rt_pri" {
    description = "Private Subnet Dictionary Value"
    type = map(string)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Optional Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "gw_id" {
    description = "Gateway IDs (ex> Transit Gateway)"
    default = null
    type = map(string)
}

variable "endpoint_id" {
    description = "Endpoint IDs (ex> Network Firewall Endpoint)"
    default = null
    type = map(string)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Optional Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Route
#
# resource "aws_route" "lb_route" {
#     route_table_id            = var.r
#
#     destination_cidr_block - (Optional) The destination CIDR block.
#             destination_cidr_block    = "10.0.1.0/22"
#     destination_ipv6_cidr_block - (Optional) The destination IPv6 CIDR block.
#     destination_prefix_list_id - (Optional) The ID of a managed prefix list destination.
#
#
#     carrier_gateway_id - (Optional) Identifier of a carrier gateway. This attribute can only be used when the VPC contains a subnet which is associated with a Wavelength Zone.
#     core_network_arn - (Optional) The Amazon Resource Name (ARN) of a core network.
#     egress_only_gateway_id - (Optional) Identifier of a VPC Egress Only Internet Gateway.
#     gateway_id - (Optional) Identifier of a VPC internet gateway or a virtual private gateway. Specify local when updating a previously imported local route.
#     nat_gateway_id - (Optional) Identifier of a VPC NAT gateway.
#     local_gateway_id - (Optional) Identifier of a Outpost local gateway.
#     network_interface_id - (Optional) Identifier of an EC2 network interface.
#     transit_gateway_id - (Optional) Identifier of an EC2 Transit Gateway.
#     vpc_endpoint_id - (Optional) Identifier of a VPC Endpoint.
#     vpc_peering_connection_id - (Optional) Identifier of a VPC peering connection.
#
# }
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# resource "aws_route" "pri_mgmt" {
#     route_table_id = var.rt_pri["pri_mgmt"]

#     destination_cidr_block    = "0.0.0.0/0"
#     gateway_id  = var.gw_id["igw"]
# }


# resource "aws_route" "dummy_route_1" {
#     route_table_id = aws_route_table.rt_pri["pri_elb"].id
#     destination_cidr_block = "0.0.0.0/0"
#     vpc_endpoint_id = var.nfw_endpoint_id
# }

resource "aws_route" "trust_route_1" {
    route_table_id = var.rt_pri["pri_trust"]
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.gw_id["tgw"]
}

# resource "aws_route" "ha_route_1" {
#     route_table_id = aws_route_table.rt_pri["pri_ha"].id
#     destination_cidr_block = "0.0.0.0/0"
#     vpc_endpoint_id = var.nfw_endpoint_id
# }

# resource "aws_route" "untrust_route_1" {
#     route_table_id = aws_route_table.rt_pri["pri_untrust"].id
#     destination_cidr_block = "0.0.0.0/0"
#     vpc_endpoint_id = var.nfw_endpoint_id
# }

# resource "aws_route" "mgmt_route_1" {
#     route_table_id = aws_route_table.rt_pri["pri_mgmt"].id
#     destination_cidr_block = "0.0.0.0/0"
#     vpc_endpoint_id = var.nfw_endpoint_id
# }




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Optional Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## 




## Suricata Rule
resource "aws_networkfirewall_rule_group" "example" {
    capacity = 100
    name     = "example"
    type     = "STATEFUL"
    rules    = file("example.rules")

    tags = {
        Tag1 = "Value1"
        Tag2 = "Value2"
    }
}