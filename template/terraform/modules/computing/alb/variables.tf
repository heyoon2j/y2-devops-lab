variable "vpc_id" {
    description = "VPC's ID"
    type = string
    # validation { 
    #     condition = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.cidr_block))
    #     error_message = "like 10.0.0.0/16, 172.16.30.0/24 ..."
    # }
}

variable "alb" {
    description = "Application Load Balancer Configuration"
    type = list(object({
        name = string
        internal = bool
        load_balancer_type = string     # "application"
        subnets = list(string)
        ip_address_type = string        # "ipv4"
        security_groups = list(string)

        enable_deletion_protection = bool   # false

        # Application Option
        idle_timeout = number
        enable_http2 = bool
        drop_invalid_header_fields = bool
        preserve_host_header = bool
        desync_mitigation_mode = string #"defensive"
        enable_waf_fail_open = bool

        log_enabled = bool
        log_bucket  = string
        log_prefix  = string

        tags = map(string)
    }))
}

variable "targetGroup" {
    description = "Application Load Balancer Configuration"
    type = list(object({
        name     = string
        target_type = string    # "instance", "ip", "lambda", "alb"
        port     = number
        protocol = string           # GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS,ㅜUDP
        protocol_version = string   # HTTP1, HTTP2, GRPC
        # if Type = "ip"
        ip_address_type = string

        #ALB Option
        deregistration_delay = number
        slow_start = number
        load_balancing_algorithm_type = string   # round_robin or least_outstanding_requests

        st_enabled = bool
        st_cookie_name = string                 #"test-cookie"
        st_cookie_duration = string             #86400          # 1 ~ 604800
        st_type = string                        #"lb_cookie"               # lb_cookie, app_cookie

        hc_enabled = bool
        hc_port = any                            #"traffic-port"            # 1-65535, or traffic-port. Defaults to traffic-port.
        hc_protocol = string                    #"HTTP"                # 
        healthy_threshold = number              #3
        unhealthy_threshold = number            #3
        hc_interval = number                    #30
        hc_timeout = number                     #5
        hc_path = string                        #"/test/index.html"
        hc_matcher = string                     #"200"

        tags = map(string)
    }))
}
