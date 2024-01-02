# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## TGW
variable "tgw_id" {
    description = "TGW ID"
    type = string
}

## TGW Route Table
variable "tgw_rt" {
    description = "TGW Route Table"
    type = map(string)
}


## Attachment
variable "attachment_vpc" {
    description = "Information for attachment VPC"
    type = map(string)
}

variable "attachment_vpn" {
    description = "Information for attachment VPN"
    type = map(string)
}

variable "attachment_dx" {
    description = "Information for attachment DX"
    type = map(string)
}

variable "attachment_peering" {
    description = "Information for attachment TGW Peering"
    type = map(string)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Route
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## VPC_ACL_DR Route
resource "aws_ec2_transit_gateway_route_table_association" "route_dr_acl_as_attatch_acl_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_acl"]
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_acl_dr"]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "route_dr_acl_pr_attach_dmz_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_acl"]
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_dmz_dr"]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "route_dr_acl_pr_shared_attach_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_acl"]
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_shared_dr"]
}




## VPC_APPLICATION_DR Route
resource "aws_ec2_transit_gateway_route_table_association" "route_dr_applications_as_attach_dmz_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_applications"]
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_dmz_dr"]
}

resource "aws_ec2_transit_gateway_route_table_association" "route_dr_applications_as_attach_shared_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_applications"]
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_shared_dr"]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "route_dr_applications_pr_attach_acl_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_applications"]
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_acl_dr"]
}


resource "aws_ec2_transit_gateway_route" "route_dr_applications_rt_attach_acl_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_applications"]
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_acl_dr"]
}



## VPC_PEERING_DR Route
resource "aws_ec2_transit_gateway_route" "route_dr_peering_rt_attach_acl_dr" {
    transit_gateway_route_table_id = var.tgw_rt["route_dr_spoke-peering"]
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = var.attachment_vpc["vpc_acl_dr"]
}