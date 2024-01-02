# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Transit Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "tgw_name" {
    description = "TGW Name"
    type = string
}

variable "amazon_side_asn" {
    description = "Amazon Side ASN for AWS"
    type = number
    default = 64512
    validation {
        condition = (var.amazon_side_asn >= 64512  && var.amazon_side_asn <= 65534) || (var.amazon_side_asn >= 4200000000  && var.amazon_side_asn <= 4294967294)
        error_message = "Range : 64512 <= ASN Number <= 65534 or 4200000000 <= ASN Number <= 4294967294"
    }
}

## 연결된 교차 계정 연결을 자동으로 수락할지 여부
variable "auto_accept_shared_attachments" {
    description = "Auto Accept for across account"
    type = string
    default = "disable"
    validation {
        condition = contains(["disable", "enable"], var.auto_accept_shared_attachments)
        error_message = "Only disable or enable"
    }
}

# TGW에 Default Routing Table 할당
variable "default_route_table_association" {
    description = "Use Default route table for association"
    type = string
    default = "disable"
    validation {
        condition = contains(["disable", "enable"], var.default_route_table_association)
        error_message = "Only disable or enable"
    }

}

variable "default_route_table_propagation" {
    description = "Use Default route table for propagation"
    type = string
    default = "disable"
    validation {
        condition = contains(["disable", "enable"], var.default_route_table_propagation)
        error_message = "Only disable or enable"
    }
}

# DNS Support
variable "dns_support" {
    description = "Use AWS DNS Support"
    type = string
    default = "enable"
    validation {
        condition = contains(["disable", "enable"], var.dns_support)
        error_message = "Only disable or enable"
    }
}
# VPN ECMP Routing
variable "vpn_ecmp_support" {
    description = "Use VPN ECMP Support"
    type = string
    default = "enable"
    validation {
        condition = contains(["disable", "enable"], var.vpn_ecmp_support)
        error_message = "Only disable or enable"
    }
}
# Multicast Support
variable "multicast_support" {
    description = "Use Multicasting"
    type = string
    default = "disable"
    validation {
        condition = contains(["disable", "enable"], var.multicast_support)
        error_message = "Only disable or enable"
    }
}

variable "tags" {
    description = "TGW Tags"
    default = null
    type = map(any)
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (VPN)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "attachment_vpc" {
    description = "Information for attachment VPC"
    type = map(object({
        name = string
        vpc_id = string
        subnet_ids = list(string)
        tags = optional(map(any), null)
    }))
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (VPN) / 수정 필요!!
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "attachment_vpn" {
    description = "Information for attachment VPN"
    type = map(any)
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (DX) / 수정 필요!!
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "attachment_dx" {
    description = "Information for attachment DX"
    type = map(any)
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Attachment (TGW Peering)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "attachment_peering" {
    description = "Information for attachment TGW Peering"
    type = map(object({
        name                    = string
        peering_id              = string
        peer_account_id         = string
        peer_region             = string
        peer_transit_gateway_id = string
    }))
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "tgw_rt" {
    description = "Routing Table for TGW"
    type = map(object({
        name = string
        tags = optional(map(any),null)
    }))
}
