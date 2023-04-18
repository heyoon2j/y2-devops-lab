variable "vpc_name" {
    description = "VPC Name"
    type = string
}

variable "cidr_block" {
    description = "VPC IPv4 CIDR"
    type = string
    #validation { 10.0.0.0/16, 172.16.30.0/24 ... }
}

variable "ipv6_cidr_block" {
    description = "VPC IPv6 CIDR"
    type = string
    #validation {}
}

variable "instance_tenancy" {
    description = "VPC에서 생성하는 인스턴스의 테넌시 기본 설정"
    type = string
    default = "default"
    #validation { "default"(Default), "dedicated" }
}

variable "enable_dns_support" {
    description = "VPC에서 DNS 지원을 활성화/비활성화"
    type = bool
    default = true
    #validation { true (Default), false }
}

variable "enable_dns_hostnames" {
    description = "Public IP Address에 Hostname을 받을지에 대한 여부"
    type = bool
    default = false
    #validation { true, false (Default) }
}