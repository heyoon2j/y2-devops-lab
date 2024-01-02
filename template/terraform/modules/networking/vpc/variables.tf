# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Common
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "available_zons" {
    description = "Available zone list"
    type = list(string)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VPC
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "vpc_name" {
    description = "VPC name"
    type = string
}

variable "cidr_block" {
    description = "VPC IPv4 CIDR"
    type = string
    validation { 
        condition = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.cidr_block))
        error_message = "like 10.0.0.0/16, 172.16.30.0/24 ..."
    }
}

/*
variable "ipv6_cidr_block" {
    description = "VPC IPv6 CIDR"
    type = string
    #validation {}
}
*/

variable "instance_tenancy" {
    description = "VPC에서 생성하는 인스턴스의 테넌시 기본 설정"
    type = string
    default = "default"
    #validation { "default"(Default), "dedicated" }
    validation {
        condition = contains(["default", "dedicated"], var.instance_tenancy)
        error_message = "Only default or dedicated"
    }
}

variable "enable_dns_support" {
    description = "VPC에서 DNS 지원을 활성화/비활성화"
    type = bool
    default = true
    #validation { true (Default), false }
    validation {
        condition = var.enable_dns_support == true || var.enable_dns_support == false
        error_message = "Only true or false"
    }
}

variable "enable_dns_hostnames" {
    description = "Public IP Address에 Hostname을 받을지에 대한 여부"
    type = bool
    default = false
    #validation { true, false (Default) }
    validation {
        condition = var.enable_dns_hostnames == true || var.enable_dns_hostnames == false
        error_message = "Only true or false"
    }
}

variable "enable_network_address_usage_metrics" {
    description = "Network Address 사용량을 CW 지표 활성화 여부"
    type = bool
    default = false

    validation {
        condition = var.enable_network_address_usage_metrics == true || var.enable_network_address_usage_metrics == false
        error_message = "Only true or false"
    }    
}

variable "tags" { 
    description = "Tags for VPC resource"
    type = map(string)
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "sbn_common_config" {
    description = "Subnet default config"
    type = object({
        naming_rule = string
        assign_ipv6_address_on_creation = optional(bool, false)
        map_public_ip_on_launch = optional(bool, false)
        #private_dns_hostname_type_on_launch =  string
        tags = optional(map(any),null)
    })
}

variable "sbn_pub" {
    description = "Public Subnet Dictionary Value"
    type = map(object({
        name = string
        cidr_block = string
        ipv6_cidr_block = optional(string, null)
        availability_zone = string
        route_table = optional(string, null)
        tags = optional(map(any), null)
    }))
}

variable "sbn_pri" {
    description = "Private Subnet Dictionary Value"
    type = map(object({
        name = string
        cidr_block = string
        ipv6_cidr_block = optional(string, null)
        availability_zone = string
        route_table = optional(string, null)
        tags = optional(map(any), null)
    }))
}

variable "tgw_attachment_subnet" {
    description = "Subnet for attaching TGW"
    type = list(string)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Routing Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "rt_common_config" {
    description = "Routing Table default config"
    type = object({
        naming_rule = string
        tags = optional(map(any),null)
    })
}

variable "rt_pub" {
    description = "Public Routing Table"
    type = map(object({
        name = string
        tags = optional(map(any),null)
    }))
}

variable "rt_pri" {
    description = "Private Routing Table"
    type = map(object({
        name = string
        tags = optional(map(any),null)
    }))
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Routing Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "igw_name" {
    description = "Internet Gateway Name"
    default = null
    type = string
}

variable "igw_tags" {
    description = "Internet Gateway Tags"
    default = null
    type = map(any)
}