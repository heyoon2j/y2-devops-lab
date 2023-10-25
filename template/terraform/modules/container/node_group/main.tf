/*
# EKS Cluster
1. EKS Cluster
    1) Application Load Balancer 생성
    2) Target Group 생성
    3) Listener 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장)
    4) Listener Rule 생성
    * Attachment는 직접 / 이유 : 변경되는 리소스 자원이므로
*/


## Input Value



## Outpu Value




############################################################


resource "aws_eks_node_group" "example" {
    cluster_name    = aws_eks_cluster.example.name
    node_group_name = "example"
    node_role_arn   = aws_iam_role.example.arn
    subnet_ids      = aws_subnet.example[*].id

    scaling_config {
        desired_size = 1
        max_size     = 2
        min_size     = 1
    }

    update_config {
        max_unavailable = 1
    }

    # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
    # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
    depends_on = [
        aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
    ]
}







############################################################
# 1. ALB
/*
'Application Load Balancer Resource'

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
        default = "application"
        validation { "application" (Default), "gateway", "network" }

    subnets            = [for subnet in aws_subnet.public : subnet.id]

    ip_address_type
        description = "IP Address Type"
        type = string
        default = "ipv4"
        validation { "ipv4", "dualstack" }

    security_groups    = [aws_security_group.lb_sg.id]

    enable_deletion_protection = true
        description = "Is enable to delete LB (Protection Setting)"
        type = bool
        default = true
        validation { true, false (Default) }

    # Application Option
    idle_timeout = 60
        description = "Load Balancer Type"
        type = string
        default = "application"
        validation { "application" (Default), "gateway", "network" }

    enable_http2
        description = "Is enable to use HTTP2"
        type = bool
        default = true
        validation { true (Default), false }

    drop_invalid_header_fields
        description = "Drop invalid header fields"
        type = bool
        default = false
        validation { true, false (Default) }

    preserve_host_header
        description = "Preserve host header"
        type = bool
        default = false
        validation { true, false (Default) }
    
    desync_mitigation_mode
        description = "Mode setting for HTTP Desync"
        type = string
        default = "defensive"
        validation { "monitor", "defensive" (Default), "strictest" }

    enable_waf_fail_open
        description = "Open when WAF is failed"
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
    count = length(var.alb)
    filter {
        name   = "vpc-id"
        values = [var.vpc_id]
    }
    filter {
        name   = "tag:Name"
        values = var.alb[count.index]["subnets"]
    }
}



data "aws_security_groups" "selected" {
    count = length(var.alb)

    filter {
        name   = "tag:Name"
        values = var.alb[count.index]["security_groups"]
    }

    filter {
        name   = "vpc-id"
        values = [var.vpc_id]
    }
}



resource "aws_lb" "alb-proj" {
    count = length(var.alb)

    name               = var.alb[count.index]["name"]
    internal           = var.alb[count.index]["internal"] 
    load_balancer_type = var.alb[count.index]["load_balancer_type"]
    subnets            = data.aws_subnets.selected[count.index].ids
    ip_address_type = var.alb[count.index]["ip_address_type"] 
    security_groups    = data.aws_security_groups.selected[count.index].ids

    enable_deletion_protection = var.alb[count.index]["enable_deletion_protection"]

    # Application Option
    idle_timeout = var.alb[count.index]["idle_timeout"]
    enable_http2 = var.alb[count.index]["enable_http2"]
    drop_invalid_header_fields = var.alb[count.index]["drop_invalid_header_fields"]
    preserve_host_header = var.alb[count.index]["preserve_host_header"]
    desync_mitigation_mode = var.alb[count.index]["desync_mitigation_mode"]
    enable_waf_fail_open = var.alb[count.index]["enable_waf_fail_open"]

    access_logs {
        enabled = var.alb[count.index]["log_enabled"]
        bucket  = var.alb[count.index]["log_bucket"] == null ? "not_use" : var.alb[count.index]["bucket"]
        prefix  = var.alb[count.index]["log_prefix"]
    }

    tags = var.alb[count.index]["tags"]
}



/*
'ALB Listener Resource'

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
        default = HTTP
        validation { "HTTP", "HTTPS" }

    protocol_version
        description = "Protoclo Version"
        type = string
        default = "HTTP1"
        validation { "HTTP1", "HTTP2", "GRPC" }

    #ALB Option
    deregistration_delay
        description = "Deregistration delay time"
        type = number
        default = 300
        validation { 0 - 3600, 300 (Default) }

    slow_start
        description = "Warming up time after set target"
        type = number
        default = 0
        validation { 0 (==Disable, Default), 30-900 }
    
    load_balancing_algorithm_type
        description = "Load balancing algorithm type"
        type = string
        default = "round_robin"
        validation { "round_robin", "least_outstanding_requests" }

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
        default = "HTTP"
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

    path
        description = "Destination for the health check request"
        type = string
        default = "/"
        validation { "^/*" }

    matcher
        description = "Response codes to use when checking for a healthy responses from a target"
        type = string
        default = "200"
        validation { "200" or" 300-302" }
*/

# Instance
resource "aws_lb_target_group" "tg-proj" {
    count = length(var.targetGroup)

    name     = var.targetGroup[count.index]["name"]
    vpc_id   = var.vpc_id
    target_type = var.targetGroup[count.index]["target_type"]
    port     = var.targetGroup[count.index]["port"]
    protocol = var.targetGroup[count.index]["protocol"]
    protocol_version = var.targetGroup[count.index]["protocol_version"]

    #ALB Option
    deregistration_delay = var.targetGroup[count.index]["deregistration_delay"]
    slow_start = var.targetGroup[count.index]["slow_start"]
    load_balancing_algorithm_type = var.targetGroup[count.index]["load_balancing_algorithm_type"]

    stickiness {
        enabled = var.targetGroup[count.index]["st_enabled"]
        cookie_name = var.targetGroup[count.index]["st_cookie_name"]
        cookie_duration = var.targetGroup[count.index]["st_cookie_duration"]
        type = var.targetGroup[count.index]["st_type"] == null ? "lb_cookie" : var.targetGroup[count.index]["st_type"] 
    }

    health_check {
        enabled = var.targetGroup[count.index]["hc_enabled"]
        port = var.targetGroup[count.index]["hc_port"]
        protocol = var.targetGroup[count.index]["hc_protocol"]
        healthy_threshold = var.targetGroup[count.index]["healthy_threshold"]
        unhealthy_threshold = var.targetGroup[count.index]["unhealthy_threshold"]
        interval = var.targetGroup[count.index]["hc_interval"]
        timeout = var.targetGroup[count.index]["hc_timeout"]
        path = var.targetGroup[count.index]["hc_path"]
        matcher = var.targetGroup[count.index]["hc_matcher"]
    }

    tags = var.targetGroup[count.index]["tags"]
}


/*
'ALB Listener Resource'
    직접 생성
*/
/*
resource "aws_lb_listener" "alb-listen-proj-temp" {
    load_balancer_arn = aws_lb.front_end.arn
    port              = "443"
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.front_end.arn
    }
}

resource "aws_lb_listener_rule" "alb-listen-rule-proj-temp" {
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