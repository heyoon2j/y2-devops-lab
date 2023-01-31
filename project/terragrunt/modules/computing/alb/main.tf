/*
# Application Load Balancer
1. ALB
    1) Application Load Balancer 생성
    2) Target Group 생성
    3) Listener 생성 (어떤, 무엇을, 어떻게 연결을 할 것인지 등의 정보가 저장)
    4) Listener Rule 생성
    * Attachment는 직접 / 이유 : 변경되는 리소스 자원이므로
*/


## Input Value



## Outpu Value




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

resource "aws_lb" "alb-proj" {
    name               = "alb-proj-temp"
    internal           = true
    load_balancer_type = "application"
    subnets            = [for subnet in aws_subnet.public : subnet.id]
    ip_address_type = "ipv4"

    security_groups    = [aws_security_group.lb_sg.id]

    enable_deletion_protection = true

    # Application Option
    idle_timeout = 60
    enable_http2 = true
    drop_invalid_header_fields = false
    preserve_host_header = false
    desync_mitigation_mode = "defensive"
    enable_waf_fail_open = false

    access_logs {
        bucket  = aws_s3_bucket.lb_logs.bucket
        prefix  = "test-lb"
        enabled = true
    }

    tags = {
        Environment = "production"
    }
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
resource "aws_lb_target_group" "tg-proj-temp" {
    name     = "tf-example-lb-tg"
    vpc_id   = aws_vpc.main.id
    target_type = "instance"
    port     = 80
    protocol = "HTTP"
    protocol_version = "HTTP1"

    #ALB Option
    deregistration_delay = 300
    slow_start = 0
    load_balancing_algorithm_type = "round_robin"
    #stickiness = {}

    health_check = {
        enabled = true
        #port = 8080 - (Optional) Port to use to connect with the target. Valid values are either ports 1-65535, or traffic-port. Defaults to traffic-port.
        protocol = "HTTP"
        healthy_threshold = 3
        unhealthy_threshold = 3
        interval = 30
        timeout = 5
        path = "/test/index.html"
        matcher = "200"
    }

    tags = {
        Environment = "production"
    }
}

# IP
resource "aws_lb_target_group" "ip-example" {
    name        = "tf-example-lb-tg"
    target_type = "ip"
    "instance", "ip", "lambda", "alb"
    ip_address_type = "ipv4"
    "ipv4", "ipv6"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
}


/*
'ALB Listener Resource'
    직접 생성
*/

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





/*
# VPC
1. VPC
    1) VPC 생성
    2) Subnet 생성
2. NAT Gateway
    1) EIP 생성
    2) NAT Gateway 생성
3. IGW Gateway
    1) IGW Gateway 생성
4. Routing
    1) Routing Table 생성
    2) Routing Table Association
    3) Routing Table의 Route 추가
*/


## Input Value



## Outpu Value


###########################################################
locals {
    pub_rt_cnt = var.pub_rt != 0 ? length(var.pub_rt) : 0
    pri_rt_cnt = var.pri_rt != 0 ? length(var.pri_rt) : 0
    azs_cnt = var.use_azs != null ? length(var.use_azs) : 1
}



############################################################
# 1. VPC
/*
'VPC Resource'

Args:
    cidr_block
        description = "VPC IPv4 CIDR"
        type = string
        validation { 10.0.0.0/16, 172.16.30.0/24 ... }

    ipv6_cidr_block 
        description = "VPC IPv6 CIDR"
        type = string
        validation {}

    instance_tenancy
        description = "VPC에서 생성하는 인스턴스의 테넌시 기본 설정"
        type = string
        default = "default"
        validation { "default"(Default), "dedicated" }

    enable_dns_support
        description = "VPC에서 DNS 지원을 활성화/비활성화"
        type = bool
        default = true
        validation { true (Default), false }
    
    enable_dns_hostnames
        description = "Public IP Address에 Hostname을 받을지에 대한 여부"
        type = bool
        default = false
        validation { true, false (Default) }

*/

resource "aws_vpc" "vpc-proj" {
    cidr_block = var.cidr_block

    #ipv6_cidr_block = var.vpc_v6cidr

    instance_tenancy = var.instance_tenancy # "default"

    enable_dns_hostnames = var.enable_dns_hostnames # true
    enable_dns_support = var.enable_dns_support # true

    # enable_classiclink = "false"
    # enable_classiclink_dns_support = "false"

    tags = {
        Name = "vpc-${var.proj_name}-${var.proj_env}-${var.proj_region}"
    }
}

/*
'Subnet Resource'

Args:
    subnet_name
        description = "Sunbet Name"
        type = string
        validation

    vpc_id
        description = "VPC ID"
        type = string
        validation {}

    cidr_block
        description = "Subnet IPv4 CIDR"
        type = string
        validation { 10.0.0.0/24, 172.16.30.0/26 ... }

    availability_zone
        description = "Availablity Zone"
        type = string
        validation { ap-northeast-2a, ap-northeast-2c ... }

    private_dns_hostname_type_on_launch
        description = "Private Hostname FQDN 지정 시, 들어갈 내용 선택"
        type = string
        validation { ip-name, resource-name }

    ipv6_cidr_block
        description = "Subnet IPv6 CIDR"
        type = string
        validation { ... }

    assign_ipv6_address_on_creation
        description = "Use IPv6 address or not "
        type = bool
        validation { true, false (Default) }

    map_public_ip_on_launch
        description = "해당 Subnet에서 인스턴스 시작 시, Public IP 할당할지 여부"
        type = bool
        validation { true, false (Default) }
*/

resource "aws_subnet" "sbn-proj-pub" {
    count = var.pub_subnet["subnet_name"] != null ? length(var.pub_subnet["subnet_name"]) : 0

    vpc_id = aws_vpc.vpc-proj.id
    cidr_block = var.pub_subnet["cidr_block"][count.index]
    availability_zone = var.pub_subnet["availability_zone"][count.index]
    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    assign_ipv6_address_on_creation = var.pub_subnet["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = var.pub_subnet["map_public_ip_on_launch"]

    tags = {
        Name = "sbn-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pub_subnet["subnet_name"][count.index]}"
    }
}

resource "aws_subnet" "sbn-proj-pri" {
    count = var.pri_subnet["subnet_name"] != null ? length(var.pri_subnet["subnet_name"]) : 0

    vpc_id = aws_vpc.vpc-proj.id
    cidr_block = var.pri_subnet["cidr_block"][count.index]
    availability_zone = var.pri_subnet["availability_zone"][count.index]
    #private_dns_hostname_type_on_launch =  
    #ipv6_cidr_block =
    assign_ipv6_address_on_creation = var.pri_subnet["assign_ipv6_address_on_creation"]
    map_public_ip_on_launch = var.pri_subnet["map_public_ip_on_launch"]

    tags = {
        Name = "sbn-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pri_subnet["subnet_name"][count.index]}"
    }
}

data "aws_subnet" "attahment" {
    count = length(var.attachment_subnet)
    filter {
        name   = "tag:Name"
        values = ["sbn-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.attachment_subnet[count.index]}"]
    }

    depends_on = [
        aws_subnet.sbn-proj-pub,
        aws_subnet.sbn-proj-pri
    ]
}

##########################################################
# Routing Table

/*
'Routing Resource'

Args:

    vpc_id
        description = " VPC ID"
        type = string
        validation {}

*/

/*
    route = [
        {
           cidr_block = "10.0.1.0/24"
           gateway_id = aws_internet_gateway.example.id
        }
        {
           cidr_block = "10.0.1.0/24"
           transit_gateway_id = aws_ec2_transit_gateway.tgw-y2net-prd-an2.id        
        }
    ]
*/
## Association 할 때, 기본적으로 local에 대한 Routing은 자동으로 추가된다.
resource "aws_route_table" "rt-proj-pub" {
    count = local.pub_rt_cnt

    vpc_id = aws_vpc.vpc-proj.id
    #route = var.pub_rt[count.index]["route"]

    tags = {
        Name = "rt-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pub_rt[count.index]}"
        attach_igw = "true"
    }
}

resource "aws_route_table_association" "rt-assoc-proj-pub" {
    count = var.pub_subnet["subnet_name"] != null ? length(var.pub_subnet["subnet_name"]) : 0

    subnet_id = aws_subnet.sbn-proj-pub[count.index].id
    route_table_id = aws_route_table.rt-proj-pub[local.pub_rt_cnt == 1 ? 0 : floor((count.index)/local.azs_cnt)].id
}


#### Private Routing Table
resource "aws_route_table" "rt-proj-pri" {
    count = local.pri_rt_cnt

    vpc_id = aws_vpc.vpc-proj.id
    #route = var.pri_rt[count.index]["route"]

    tags = {
        Name = "rt-${var.proj_name}-${var.proj_env}-${var.proj_region}-${var.pri_rt[count.index]}"
   }
}

resource "aws_route_table_association" "rt-assoc-proj-pri" {
    count = var.pri_subnet["subnet_name"] != null ? length(var.pri_subnet["subnet_name"]) : 0

    subnet_id = aws_subnet.sbn-proj-pri[count.index].id
    route_table_id = aws_route_table.rt-proj-pri[local.pri_rt_cnt == 1 ? 0 : floor((count.index)/local.azs_cnt)].id
}

/*
resource "aws_route" "r-proj-pri" {
    route_table_id              = "rtb-4fbb3ac4"
    destination_ipv6_cidr_block = "::/0"
    egress_only_gateway_id      = aws_egress_only_internet_gateway.egress.id
}
*/


###################################################################
# Internet Gateway
resource "aws_internet_gateway" "igw-proj" {
    count = var.use_internet_gateway == true ? 1 : 0

    vpc_id = aws_vpc.vpc-proj.id

    tags = {
        Name = "igw-${var.proj_name}-${var.proj_env}-${var.proj_region}"
    }
}

/*
resource "aws_internet_gateway_attachment" "igw-attach-proj" {
    count = var.use_internet_gateway == true ? 1 : 0

    internet_gateway_id = aws_internet_gateway.igw-proj[0].id 
    vpc_id = aws_vpc.vpc-proj.id

    depends_on = [aws_internet_gateway.igw-proj]
}
*/
/*
data "aws_route_tables" "rts_igw" {
    vpc_id = aws_vpc.vpc-proj.id

    filter {
        name = "tag:attach_igw"
        values = ["true", "True"] 
    }
}
*/

resource "aws_route" "rt-proj-pub-igw-conn" {
    count                     = local.pub_rt_cnt

    #route_table_id            = tolist(data.aws_route_tables.rts_igw.ids)[count.index]
    route_table_id = aws_route_table.rt-proj-pub[count.index].id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.igw-proj[0].id
    depends_on                = [aws_internet_gateway.igw-proj]#, aws_route_table.rt-proj-pub]
}
