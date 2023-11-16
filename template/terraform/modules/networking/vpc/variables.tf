variable "vpc_name" {
    description = "VPC Name"
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



variable "use_azs" {
    description = "Availability Zones list using in vpc"
    type = list(string)
}


## Subnet
/*
variable "pub_subnet_name" {
    description = "Subnet Name(s)"
    type = list(string)
}

variable "pub_cidr_block" {
    description = "Subnet IPv4 CIDR"
    type = list(string)
    #validation { 10.0.0.0/24, 172.16.30.0/26 ... }
    validation { 
        condition = can([for subnet in var.pub_cidr_block : regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", subnet)])
        error_message = "Like 10.0.0.0/16, 172.16.30.0/24 ..."
    }
}

variable "pub_availability_zone" {
    description = "Availablity Zone"
    type = list(string)
    #validation { ap-northeast-2a, ap-northeast-2c ... }
    validation {
        condition = can([for az in var.pub_availability_zone : regex("^[a-z]{2}-[a-z]{1,}-[1-3]{1}[a-c]{1}$", az)])
        error_message = "Like ap-northeast-2a, ap-south-2b ..."
    }
}

variable "pub_private_dns_hostname_type_on_launch" {
    description = "Private Hostname FQDN 지정 시, 들어갈 내용 선택"
    type = string
    #validation { ip-name, resource-name }
}

variable "pub_ipv6_cidr" {
    description = "Subnet IPv6 CIDR"
    type = string
    #validation { ... }
}

variable "pub_assign_ipv6_address_on_creation" {
    description = "Use IPv6 address or not "
    type = bool
    default = false
    validation {
        condition = var.pub_assign_ipv6_address_on_creation == true || var.pub_assign_ipv6_address_on_creation == false
        error_message = "Only true or false (Boolean Value)"
    }
}

variable "pub_map_public_ip_on_launch" {
    description = "해당 Subnet에서 인스턴스 시작 시, Public IP 할당할지 여부"
    type = bool
    validation { 
        condition = var.pub_map_public_ip_on_launch == true || var.pub_map_public_ip_on_launch == false
        error_message = "Only true or false (Boolean Value)"
    }
}
*/

variable "subnet_pub" {
    description = "Public Subnet Dictionary Value"
    type = map(object({
        name = string
        cidr_block = string
        availability_zone = string
        assign_ipv6_address_on_creation = optional(bool, false)
        map_public_ip_on_launch = optional(bool, false)
    }))
}

variable "subnet_pri" {
    description = "Private Subnet Dictionary Value"
    type = map(object({
        name = string
        cidr_block = string
        availability_zone = string
        assign_ipv6_address_on_creation = optional(bool, false)
        map_public_ip_on_launch = optional(bool, false)
    }))
}


#################################################################
# TGW Attachment

variable "tgw_attachment_subnet" {
    description = "Subnet for attaching TGW"
    type = list(string)
}
