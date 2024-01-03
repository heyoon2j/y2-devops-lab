/*
# Elastic Kubernetes
    1) Transit Gateway 생성
    2) Attachement 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장) / VPC, DX, VPN, TGW Peering
    3) Attachment를 Transit Gateway의 Routing Table에 Association
    4) Attachment를 Transit Gateway의 Routing Table에 Propagation
    5) Transit Gateway의 Routing Table 생성
    6) Transit Gateway Routing 추가 작업
*/


## Input Value



## Outpu Value


/*
data "aws_ec2_transit_gateway_vpc_attachment" "example" {
    count = length(var.attachment_vpc)
    filter {
        name   = "vpc-id"
        values = [var.attachment_vpc[count.indxe]["vpc_id"]]
    }
}
# data "aws_ec2_transit_gateway_peering_attachment" "example" {}
# data "aws_ec2_transit_gateway_vpn_attachment" "example" {}
# data "aws_ec2_transit_gateway_dx_gateway_attachment" "example" {}
*/

locals {
    # attachment = merge(
    #     {for attach in aws_ec2_transit_gateway_vpc_attachment.tgw-attach-vpc : attach.tags_all["Name"] => attach.vpc_id}
    #     ,{for attach in aws_ec2_transit_gateway_peering_attachment.tgw-attach-peering : attach.tags_all["Name"] => attach.peering_id}
    #     #,{for attach in peering}
    #     #,{for attach in peering}
    # )
    # router = {for rt in aws_ec2_transit_gateway_route_table.tgw-rt-proj : rt.tags_all["Name"] => rt.id}
/*
    association = [
        for rt in var.tgw_rt:{
            for assoc in rt.associationList:
                local.router[rt.name] => local.attachment[assoc]
        }
    ]
    propagation = [
        for rt in var.tgw_rt:{
            for propa in rt.propagationList:
                local.router[rt.name] => local.attachment[propa]
        }
    ]
*/
}


############################################################
# 1. Transit Gateway
/*
'Transit Gateway Resource'

Args:

variable "control_plane" {
    description = "Control_plane Information"
    type = object({
        name = string                   # Control Plane's Name
        version = optional(string)                # Control Plane's Version
        role_arn = string               # Control Plane's Role
        
        # VPC Network Config (== Physical)
        vpc_config = object({
            subnet_ids = list(string)
            security_group_ids = list(string)
            endpoint_private_access = optional(bool, true)
            endpoint_public_access  = optional(bool, false)
            public_access_cidrs = optional(list(string))
        })

        # Kubernetes Network Config (== Logical)
        kubernetes_network_config = optional(object({
            ip_family = optional(string, "ipv4")
            service_ipv4_cidr = optional(string, "10.100.0.0/16")
        }))

        # Encryption for Secrets object
        encryption_config = optional(object({
            key_arn = string
            resources = optional(list(string), ["secrets"])
        }))

        enabled_cluster_log_types = optional(list(string))
        tags = optional(map(any))

    })
}

*/

resource "aws_eks_cluster" "control_plane" {
    name = var.control_plane.name                   # Control Plane's Name
    version = var.control_plane.version             # Control Plane's Version
    role_arn = var.control_plane.role_arn           # Control Plane's Role
    
    # VPC Network Config (== Physical)
    vpc_config {
        subnet_ids = var.control_plane.vpc_config["subnet_ids"]
        security_group_ids = var.control_plane.vpc_config["security_group_ids"]
        endpoint_private_access = var.control_plane.vpc_config["endpoint_private_access"]
        endpoint_public_access  = var.control_plane.vpc_config["endpoint_public_access"]
        public_access_cidrs = var.control_plane.vpc_config["public_access_cidrs"]
    }

    # Kubernetes Network Config (== Logical)
    kubernetes_network_config {
        ip_family = var.control_plane.kubernetes_network_config["ip_family"]
        service_ipv4_cidr = var.control_plane.kubernetes_network_config["service_ipv4_cidr"]
    }

    # Encryption for Secrets object
    encryption_config {
        provider {
            key_arn = var.control_plane.encryption_config["key_arn"]
        }
        resources = var.control_plane.encryption_config["resources"]
    }

    enabled_cluster_log_types = var.control_plane.enabled_cluster_log_types
    tags = var.control_plane.tags
}



