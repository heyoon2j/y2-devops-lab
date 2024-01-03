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


resource "aws_eks_node_group" "compute_machines" {
    cluster_name    = var.compute_machines.cluster_name

    # Node Group Configuration
    node_group_name = var.compute_machines.node_group_name
    node_role_arn   = var.compute_machines.node_role_arn
    labels          = var.compute_machines.labels

    #  
    dynamic "taint" {
        for_each = var.compute_machines.taint
        content {
            key = taint.value["key"]
            value = taint.value["value"]
            effect = taint.value["effect"]
        }
    }

    # Network
    subnet_ids      = var.compute_machines.subnet_ids
    
    # EC2 Resource Spec
    launch_template {
        id = var.compute_machines.launch_template["id"]
        name = var.compute_machines.launch_template["name"]
        version = var.compute_machines.launch_template["version"]
    }
        # ami_type - (Optional) Type of Amazon Machine Image (AMI) associated with the EKS Node Group. See the AWS documentation for valid values. Terraform will only perform drift detection if a configuration value is provided.
        # release_version – (Optional) AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version.
        # instance_types - (Optional) List of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided.
        # capacity_type - (Optional) Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided.
        # disk_size - (Optional) Disk size in GiB for worker nodes. Defaults to 50 for Windows, 20 all other node groups. Terraform will only perform drift detection if a configuration value is provided.
    
    # Scaling
    scaling_config {
        desired_size = var.compute_machines.scaling_config["desired_size"]
        max_size     = var.compute_machines.scaling_config["max_size"]
        min_size     = var.compute_machines.scaling_config["min_size"]
    }

    # This is Only One
    dynamic "remote_access" {
        for_each = var.compute_machines.remote_access
        content {
            ec2_ssh_key = remote_access.value["ec2_ssh_key"]
            source_security_group_ids = remote_access.value["security_group_ids"]
        }
    }
    
    # 업데이트 사용 불가 가능 갯수 
    update_config {
        max_unavailable = var.compute_machines.update_config["max_unavailable"]
        max_unavailable_percentage = var.compute_machines.update_config["max_unavailable_percentage"]
    }

    tags = var.compute_machines.tags

    # 쓰는게 맞나?
    # version – (Optional) Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided.
    # force_update_version - (Optional) Force version update if existing pods are unable to be drained due to a pod disruption budget issue.

}
