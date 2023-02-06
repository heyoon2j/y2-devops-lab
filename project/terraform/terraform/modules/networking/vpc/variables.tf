variable "vpc_name" {
    description = "Name of VPC"
    type = string
    nullable = false
}

variable "cidr_block" {
    description = "VPC IPv4 CIDR"
    type = string
    
    validation { 
        condition = can(regex("^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$"))
        error_message = "CIDR of VPC, like 10.0.0.0/16, 172.16.30.0/24 ...)"
    }  
}

variable "ipv6_cidr_block " {
    description = "VPC IPv6 CIDR"
    type = string
    validation {}
}

variable "instance_tenancy" {
    description = "Instance tenancy in VPC"
    type = string
    default = "default"
    validation { 
        condition = can(regex("(default)|(dedicated)", var.instance_tenancy))
        error_message = "The instance_tenancy must be a vaild value, default or dedicated"
    }
    # "default"(Default), "dedicated"
}

variable "enable_dns_support" {
    description = "VPC에서 DNS 지원을 활성화/비활성화"
    type = bool
    default = true
    validation { 
        condition = can(regex("(true)|(false)", var.instance_tenancy))
        error_message = "The enable_dns_support must be a vaild value, true or false"
    }
    # true (Default), false
}

variable "enable_dns_hostnames" {
description = "VPC에서 DNS Hostname 사용 활성화/비활성화"
    type = bool
    default = true
    validation { 
        condition = can(regex("(true)|(false)", var.instance_tenancy))
        error_message = "The enable_dns_hostnames must be a vaild value, true or false"
    }
    # false (Default) / true
}   
    
