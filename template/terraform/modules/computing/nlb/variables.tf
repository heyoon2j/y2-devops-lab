variable "vpc_id" {
    description = "VPC's ID"
    type = string
    # validation { 
    #     condition = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.cidr_block))
    #     error_message = "like 10.0.0.0/16, 172.16.30.0/24 ..."
    # }
}

variable "nlb" {
    description = "Network Load Balancer Configuration"
    type = list(object({
        name = string
        internal = bool
        load_balancer_type = string     # "application"
        subnets = list(string)
        ip_address_type = string        # "ipv4"
        security_groups = list(string)

        enable_deletion_protection = bool   # false

        # NLB Option
        enable_cross_zone_load_balancing = bool

        log_enabled = bool
        log_bucket  = string
        log_prefix  = string

        tags = map(string)
    }))
}

variable "targetGroup" {
    description = "Network Load Balancer Configuration"
    type = list(object({
        name     = string
        target_type = string    # "instance", "ip", "lambda", "alb"
        port     = number
        protocol = string           # GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS,ㅜUDP
        # if Type = "ip"
        ip_address_type = string

        #NLB Option
        deregistration_delay = number
        connection_termination = bool
        preserve_client_ip = bool
        proxy_protocol_v2 = bool

        st_enabled = bool
        st_type = string                        #"lb_cookie"               # lb_cookie, app_cookie

        hc_enabled = bool
        hc_port = any                            #"traffic-port"            # 1-65535, or traffic-port. Defaults to traffic-port.
        hc_protocol = string                    #"HTTP"                # 
        healthy_threshold = number              #3
        unhealthy_threshold = number            #3
        hc_interval = number                    #30
        hc_timeout = number                     #5

        tags = map(string)
    }))
}
