variable "vpc_id" {
    description = "VPC ID"
    type = string
  
}

variable "sbn_pri" {
    description = "Private Subnet"
    type = map 
}

variable "sbn_pub" {
    description = "Public Subnet"
    type = map
}

variable "rt_pub" {
    description = "Public Subnet Dictionary Value"
    type = map(object({
        name = string
    }))
}

variable "rt_pri" {
    description = "Private Subnet Dictionary Value"
    type = map(object({
        name = string
    }))
}

variable "rt_pub_assoc" {
    description = "Public Subnet Association List"
    type = map(any)
}

variable "rt_pri_assoc" {
    description = "Private Subnet Dictionary Association List"
    type = map(any)
}


## Internet Gateway
variable "internet_gateway" {
    description = "Use internet gateway"
    type = map(any)
}



##########################################################
# Routing Table

/*
'Routing Resource'

Args:

    vpc_id
        description = " VPC ID"
        type = string
        validation {}

*/

/*
    route = [
        {
           cidr_block = "10.0.1.0/24"
           gateway_id = aws_internet_gateway.example.id
        }
        {
           cidr_block = "10.0.1.0/24"
           transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id        
        }
    ]
*/
## Association 할 때, 기본적으로 local에 대한 Routing은 자동으로 추가된다.

resource "aws_route_table" "rt_pub" {
    for_each = var.rt_pub

    vpc_id = var.vpc_id
    #route = []

    tags = {
        Name = each.value["name"]
    }
}
resource "aws_route_table_association" "rt_pub_assoc" {
    for_each = var.rt_pub_assoc

    route_table_id = aws_route_table.rt_pub[each.value].id
    subnet_id = var.sbn_pub[each.key]
}


#### Private Routing Table
resource "aws_route_table" "rt_pri" {
    for_each = var.rt_pri

    vpc_id = var.vpc_id
    #route = []

    tags = {
        Name = each.value["name"]
    }
}
resource "aws_route_table_association" "rt_pri_assoc" {
    for_each = var.rt_pri_assoc

    route_table_id = aws_route_table.rt_pri[each.value].id
    subnet_id = var.sbn_pri[each.key]
}


###################################################################
# Internet Gateway

resource "aws_internet_gateway" "igw_main" {
    count = var.internet_gateway != null ? 1 : 0

    vpc_id = var.vpc_id

    tags = {
        Name = var.internet_gateway != null ? "${var.internet_gateway["name"]}" : 0
    }
}
/*
resource "aws_internet_gateway_attachment" "igw_attach" {
    count = var.internet_gateway != null ? 1 : 0

    internet_gateway_id = aws_internet_gateway.igw_main[0].id 
    vpc_id = aws_vpc.vpc_main.id

    depends_on = [aws_internet_gateway.igw_main]
}
*/
/*
data "aws_route_tables" "rts_igw" {
    vpc_id = aws_vpc.vpc_main.id

    filter {
        name = "tag:attach_igw"
        values = ["true", "True"]
    }
}
*/

resource "aws_route" "rt_pub_igw_conn" {
    for_each = var.rt_pub

    route_table_id = aws_route_table.rt_pub[each.key].id

    destination_cidr_block    = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.igw_main[0].id

    depends_on  = [aws_internet_gateway.igw_main, aws_route_table.rt_pub]
}



################################################################################
################################################################################
################################################################################
# Route

# variable "transit_gateway_id" {
#     description = "Transit Gateway ID"
#     type = string
#     default = "null"
# }

# resource "aws_route" "lb_route" {
#     route_table_id            = var.r

#     destination_cidr_block - (Optional) The destination CIDR block.
#             destination_cidr_block    = "10.0.1.0/22"
#     destination_ipv6_cidr_block - (Optional) The destination IPv6 CIDR block.
#     destination_prefix_list_id - (Optional) The ID of a managed prefix list destination.


    
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

# }

variable "tgw_id" {
    description = "Transit Gateway ID"
    type = string
}

variable "nfw_endpoint_id" {
    description = "Network Firewall Endpoint ID"
    type = string
}


# resource "aws_route" "dummy_route_1" {
#     route_table_id = aws_route_table.rt_pri["pri_elb"].id
#     destination_cidr_block = "0.0.0.0/0"
#     vpc_endpoint_id = var.nfw_endpoint_id
# }

resource "aws_route" "trust_route_1" {
    route_table_id = aws_route_table.rt_pri["pri_trust"].id
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.tgw_id
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
