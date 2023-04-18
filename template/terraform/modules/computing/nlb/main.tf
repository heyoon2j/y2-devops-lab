/*
# Network Load Balancer
1. NLB
    1) Network Load Balancer 생성
    2) Target Group 생성
    3) Listener 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장)
    4) Listener Rule 생성
    * Attachment는 직접 / 이유 : 변경되는 리소스 자원이므로
*/

## Input Value



## Outpu Value




############################################################
# 1. NLB
/*
'Network Load Balancer Resource'

Args:
    name
        description = "LB Name"
        type = string
        #default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    internal
        description = "Internal or Internet-facing"
        type = bool
        default = true
        validation { true, false }

    load_balancer_type
        description = "Load Balancer Type"
        type = string
        default = "network"
        validation { "application" (Default), "gateway", "network" }

    subnets            = [for subnet in aws_subnet.public : subnet.id]

    ip_address_type
        description = "IP Address Type"
        type = string
        default = "ipv4"
        validation { "ipv4", "dualstack" }

    enable_deletion_protection = true
        description = "Is enable to delete LB (Protection Setting)"
        type = bool
        default = true
        validation { true, false (Default) }


    # Network Option
    enable_cross_zone_load_balancing
        description = "Use cross zone load balancing"
        type = bool
        default = false
        validation { true, false (Default) }


    #access_logs
    bucket
        description = "For access log, S3 bucket ID"
        type = string
        #default = 
        #validation { }

    prefix  = "test-lb"
        description = "For access log, log file's prefix name"
        type = string
        #default = 
        #validation { }

    enabled
        description = "Boolean to enable access_logs"
        type = bool
        default = false
        validation { true, false (Default) }
*/

data "aws_subnets" "selected" {
    count = length(var.nlb)
    filter {
        name   = "vpc-id"
        values = [var.vpc_id]
    }
    filter {
        name   = "tag:Name"
        values = var.nlb[count.index]["subnets"]
    }
}



data "aws_security_groups" "selected" {
    count = length(var.nlb)

    filter {
        name   = "tag:Name"
        values = var.nlb[count.index]["security_groups"]
    }

    filter {
        name   = "vpc-id"
        values = [var.vpc_id]
    }
}



resource "aws_lb" "nlb-proj" {
    count = length(var.nlb)

    name               = var.nlb[count.index]["name"]
    internal           = var.nlb[count.index]["internal"] 
    load_balancer_type = var.nlb[count.index]["load_balancer_type"]
    subnets            = data.aws_subnets.selected[count.index].ids
    ip_address_type = var.nlb[count.index]["ip_address_type"] 
    #security_groups    = data.aws_security_groups.selected[count.index].ids

    enable_deletion_protection = var.nlb[count.index]["enable_deletion_protection"]

    # NLB Option
    enable_cross_zone_load_balancing = var.nlb[count.index]["enable_deletion_protection"]


    access_logs {
        enabled = var.nlb[count.index]["log_enabled"]
        bucket  = var.nlb[count.index]["log_bucket"] == null ? "not_use" : var.nlb[count.index]["bucket"]
        prefix  = var.nlb[count.index]["log_prefix"]
    }

    tags = var.nlb[count.index]["tags"]
}



/*
'NLB Listener Resource'

Args:
    name
        description = "LB Target Group Name"
        type = string
        #default = "Transit Gateway"
        #validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    vpc_id
        description = "VPC ID"
        type = string
        #default = true
        #validation { true, false }    

    target_type
        description = "Target Type"
        type = string
        default = "instance"
        validation { "instance", "ip", "lambda", "alb" }

    port
        description = "Port Number"
        type = number
        default = 80
        validation { 1 ~ 65535 }

    protocol
        description = "Protocol"
        type = string
        default = "TCP"
        validation { "TCP", "TCP_UDP", "TLS", "UDP" }


    #NLB Option
    deregistration_delay
        description = "Deregistration delay time"
        type = number
        default = 300
        validation { 0 - 3600, 300 (Default) }

    preserve_client_ip
        description = "Instance : true, IP : false"
        type = bool
        default = true
        validation { true, false }

    proxy_protocol_v2
        description = "Use this protocol when connect to other netwrok"
        type = bool
        default = false
        validation { true, false (Default) }

    connection_termination
        description = "Whether to terminate connections at the end of the deregistration timeout"
        type = bool
        default = false
        validation { true, false (Default) }

    #stickiness = {}


    #health_check
    enabled
        description = "Whether health checks are enabled"
        type = bool
        default = true
        validation { true (Default), false } 

    #health_check_port = 8080 - (Optional) Port to use to connect with the target. Valid values are either ports 1-65535, or traffic-port. Defaults to traffic-port.
    health_check_protocol
        description = "Protocol for Health Check"
        type = bool
        default = "TCP"
        validation { "HTTP", "HTTPS", "TCP" } 

    healthy_threshold
        description = "Number of consecutive health checks successes required before considering an unhealthy target healthy"
        type = number
        default = 3
        validation { 3 (Default), 2 - 10 }

    unhealthy_threshold
        description = "Number of consecutive health check failures required before considering the target unhealthy"
        type = number
        default = 3
        validation { 3 (Default), 2 - 10 }

    interval
        description = "Approximate amount of time, in seconds, between health checks of an individual target"
        type = number
        default = 30
        validation { 30, (Default), 5 - 300 }

    timeout
        description = "Amount of time, in seconds, during which no response means a failed health check."
        type = number
        default = 5
        validation { 5 (Default), 2 - 120 }

    #path
    #    description = "Destination for the health check request"
    #    type = string
    #    default = "/"
    #    validation { "^/*" }

    #matcher
    #    description = "Response codes to use when checking for a healthy responses from a target"
    #    type = string
    #    default = "200"
    #    validation { "200" or" 300-302" }
*/

resource "aws_lb_target_group" "tg-proj" {
    count = length(var.targetGroup)

    name     = var.targetGroup[count.index]["name"]
    vpc_id   = var.vpc_id
    target_type = var.targetGroup[count.index]["target_type"]
    port     = var.targetGroup[count.index]["port"]
    protocol = var.targetGroup[count.index]["protocol"]

    ip_address_type = var.targetGroup[count.index]["ip_address_type"]

    #NLB Option
    deregistration_delay = var.targetGroup[count.index]["deregistration_delay"]
    connection_termination = var.targetGroup[count.index]["connection_termination"]
    preserve_client_ip = var.targetGroup[count.index]["preserve_client_ip"]
    proxy_protocol_v2 = var.targetGroup[count.index]["proxy_protocol_v2"]


    stickiness {
        enabled = var.targetGroup[count.index]["st_enabled"]
        type = var.targetGroup[count.index]["st_type"] == null ? "source_ip" : var.targetGroup[count.index]["st_type"] 
    }

    health_check {
        enabled = var.targetGroup[count.index]["hc_enabled"]
        port = var.targetGroup[count.index]["hc_port"]
        protocol = var.targetGroup[count.index]["hc_protocol"]
        healthy_threshold = var.targetGroup[count.index]["healthy_threshold"]
        unhealthy_threshold = var.targetGroup[count.index]["unhealthy_threshold"]
        interval = var.targetGroup[count.index]["hc_interval"]
        timeout = var.targetGroup[count.index]["hc_timeout"]
    }

    tags = var.targetGroup[count.index]["tags"]
}


# IP인 경우
/*
resource "aws_lb_target_group" "ip-example" {
    name        = "tf-example-lb-tg"
    target_type = "ip"
    "instance", "ip", "lambda", "alb"
    ip_address_type = "ipv4"
    "ipv4", "ipv6"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
}*/
/*
resource "aws_lb_target_group" "tg-proj-ip" {
    count = length(var.targetGroup)

    name     = var.targetGroup[count.index]["name"]
    vpc_id   = var.vpc_id
    target_type = "ip"
    port     = var.targetGroup[count.index]["port"]
    protocol = var.targetGroup[count.index]["protocol"]

    ip_address_type = "ipv4"

    #NLB Option
    deregistration_delay = var.targetGroup[count.index]["deregistration_delay"]
    connection_termination = var.targetGroup[count.index]["connection_termination"]
    preserve_client_ip = var.targetGroup[count.index]["preserve_client_ip"]
    proxy_protocol_v2 = var.targetGroup[count.index]["proxy_protocol_v2"]


    stickiness {
        enabled = var.targetGroup[count.index]["st_enabled"]
        type = var.targetGroup[count.index]["st_type"] != null ? "source_ip" : var.targetGroup[count.index]["st_type"] 
    }

    health_check {
        enabled = var.targetGroup[count.index]["hc_enabled"]
        port = var.targetGroup[count.index]["hc_port"]
        protocol = var.targetGroup[count.index]["hc_protocol"]
        healthy_threshold = var.targetGroup[count.index]["healthy_threshold"]
        unhealthy_threshold = var.targetGroup[count.index]["unhealthy_threshold"]
        interval = var.targetGroup[count.index]["hc_interval"]
        timeout = var.targetGroup[count.index]["hc_timeout"]
    }

    tags = var.targetGroup[count.index]["tags"]
}

*/

/*
'NLB Listener Resource'
    직접 생성
*/
/*
resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.front_end.arn
    port              = "443"
    protocol          = "TLS"
    certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
    alpn_policy       = "HTTP2Preferred"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.front_end.arn
    }
}

resource "aws_lb_listener_rule" "" {
    listener_arn = aws_lb_listener.front_end.arn
    priority     = 99
    1 - 50000 (1 > 5000)

    action {
        type             = "forward"
        "forward", "redirect", "fixed-response", "authenticate-cognito","authenticate-oidc"
        target_group_arn = aws_lb_target_group.static.arn
    }

    condition {
        host_header {
            values = ["my-service.*.terraform.io"]
        }
    }

}
*/