/*
# Application Load Balancer
1. ALB
    1) Application Load Balancer 생성
    2) Target Group 생성
    3) Listener 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장)
*/


## Input Value



## Outpu Value




############################################################
# 1. ALB
/*
'Load Balancer Resource'

Args:
    description
        description = "Description"
        type = string
        default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    amazon_side_asn
        description = "AWS ASN"
        type = number
        default = 64512
        validation { 64512 ~ 65534, 4200000000 ~ 4294967294 }

    auto_accept_shared_attachments
        description = "auto acception about shared account"
        type = string
        default = "disable"
        validation { "disable" (Default), "enable" }

    default_route_table_association 
        description = "default rout table associate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    default_route_table_propagation
        description = "default rout table propagate to tgw"
        type = string
        default = "disable"
        validation { "enable" (Default), "disable" }

    dns_support
        description = "DNS Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    vpn_ecmp_support
        description = "VPN ECMP Routing Support"
        type = string
        default = "enable"
        validation { "enable" (Default), "disable" }

    multicast_support
        description = "Multicast Support"
        type = string
        default = "disable"
        validation { "enable", "disable" (Disable) }
*/

resource "aws_lb" "alb-proj-temp" {
    name               = "alb-proj-temp"
    internal           = true
    true, false
    load_balancer_type = "application"
    "application" (Default), "gateway", "network"
    subnets            = [for subnet in aws_subnet.public : subnet.id]
    ip_address_type = "ipv4"
    "ipv4", "dualstack"

    security_groups    = [aws_security_group.lb_sg.id]

    enable_deletion_protection = true
    true, false (Default)

    # Application Option
    idle_timeout = 60
    enable_http2 = true
    true (Default) / false
    drop_invalid_header_fields = false
    true, false (Default)
    preserve_host_header = false
    true, false (Default)
    
    desync_mitigation_mode = "defensive"
    "monitor", "defensive" (Default), "strictest"

    enable_waf_fail_open = false
    true, false (Default)

    access_logs {
        bucket  = aws_s3_bucket.lb_logs.bucket
        prefix  = "test-lb"
        enabled = true
    }

    tags = {
        Environment = "production"
    }
}