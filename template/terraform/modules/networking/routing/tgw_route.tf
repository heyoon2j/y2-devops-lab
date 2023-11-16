
## TGW ID
variable "tgw_id" {
    description = "TGW ID"
    type = string
}


## Attachment
variable "attatch_acl_dr" {
    description = "VPC ACL DR Attachment"
    type = string
}

variable "attatch_dmz_dr" {
    description = "VPC DMZ DR Attachment"
    type = string
}

variable "attatch_shared_dr" {
    description = "VPC Shared DR Attachment"
    type = string
}

# variable "attatch_peering_dr" {
#     description = "TGW Peering Attachment"
#     type = string
# }



########################################################################
## Route Table 
resource "aws_ec2_transit_gateway_route_table" "route_dr_acl" {  
    transit_gateway_id = var.tgw_id

    tags = {
        Name = "route-dr-acl"
    }
}
 

resource "aws_ec2_transit_gateway_route_table_association" "route_dr_acl_as_attatch_acl_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_acl.id
    transit_gateway_attachment_id  = var.attatch_acl_dr
}


resource "aws_ec2_transit_gateway_route_table_propagation" "route_dr_acl_pr_attach_dmz_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_acl.id
    transit_gateway_attachment_id  = var.attatch_dmz_dr
}

resource "aws_ec2_transit_gateway_route_table_propagation" "route_dr_acl_pr_shared_attach_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_acl.id
    transit_gateway_attachment_id  = var.attatch_shared_dr
}

## Perring Attchment 추가하기
# resource "aws_ec2_transit_gateway_route_table_propagation" "peering" {
#     transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_applications.id
#     transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.example.id
# }

# resource "aws_ec2_transit_gateway_route" "route_to_peering" {
#     transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_acl.id
#     destination_cidr_block         = "0.0.0.0/0"
#     transit_gateway_attachment_id  = var.attatch_peering_dr
# }



########################################################################
## Route Table 
resource "aws_ec2_transit_gateway_route_table" "route_dr_applications" {
    transit_gateway_id = var.tgw_id

    tags = {
        Name = "route-dr-applications"
    }
}

resource "aws_ec2_transit_gateway_route_table_association" "route_dr_applications_as_attach_dmz_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_applications.id
    transit_gateway_attachment_id  = var.attatch_dmz_dr
}

resource "aws_ec2_transit_gateway_route_table_association" "route_dr_applications_as_attach_shared_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_applications.id
    transit_gateway_attachment_id  = var.attatch_shared_dr
}

resource "aws_ec2_transit_gateway_route_table_propagation" "route_dr_applications_pr_attach_acl_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_applications.id
    transit_gateway_attachment_id  = var.attatch_acl_dr
}


resource "aws_ec2_transit_gateway_route" "route_dr_applications_rt_attach_acl_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_applications.id
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = var.attatch_acl_dr
}



########################################################################
## Route Table 
resource "aws_ec2_transit_gateway_route_table" "route_dr_peering" {
    transit_gateway_id = var.tgw_id

    tags = {
        Name = "route-dr-spoke-peering"
    }
}

# resource "aws_ec2_transit_gateway_route_table_association" "route_dr_peering_as_attach_peering" {
#     transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_peering.id
#     transit_gateway_attachment_id  = var.attatch_peering_dr
# }

resource "aws_ec2_transit_gateway_route" "route_dr_peering_rt_attach_acl_dr" {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_dr_peering.id
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = var.attatch_acl_dr
}