###############################################################

include "root" {
    path = find_in_parent_folders()
    expose = false
}

include "remote_state" {
    path   = find_in_parent_folders("remote_state.hcl")
    expose = true
}

include "provider" {
    path   = find_in_parent_folders("provider.hcl")
    expose = true
}

locals {
    config_vars = read_terragrunt_config(find_in_parent_folders("config.hcl"))
    proj_region = local.config_vars.locals.proj_region
    proj_name = local.config_vars.locals.proj_name
    proj_env = local.config_vars.locals.proj_env[2]
}

###############################################################
dependency "secure_vpc" {
    config_path = "${get_parent_terragrunt_dir("root")}//network-proto/secure/prd/vpc"
}


###############################################################
terraform {
    source = "${get_parent_terragrunt_dir("root")}//modules/computing/alb"
}

inputs = {
    vpc_id = dependency.secure_vpc.outputs.vpc["id"]


# ALB
    alb = [
        {
            name = "alb-${local.proj_name}-${local.proj_env}-ec2-readOnly"
            internal = true
            load_balancer_type = "application"
            subnets = ["sbn-${local.proj_name}-${local.proj_env}-${local.proj_region}-a-pub-untrust", "sbn-${local.proj_name}-${local.proj_env}-${local.proj_region}-b-pub-untrust"]
            ip_address_type = "ipv4"
            security_groups = ["${local.proj_name}-${local.proj_env}-http-sg"]

            enable_deletion_protection = false

            # Application Option
            idle_timeout = 60
            enable_http2 = true
            drop_invalid_header_fields = false
            preserve_host_header = false
            desync_mitigation_mode = "defensive"
            enable_waf_fail_open = false

            log_enabled = false
            log_bucket  = null
            log_prefix  = null

            tags = {
                Name = "alb-${local.proj_name}-${local.proj_env}-ec2-readOnly"
                Test = "test"
            }            
        }
    ]

    targetGroup = [
        {
            name     = "tg-${local.proj_name}-${local.proj_env}-${local.proj_region}-proto-80"
            target_type = "instance"    # "instance", "ip", "lambda", "alb"
            port     = 80
            protocol = "HTTP"           # GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS,ㅜUDP
            protocol_version = "HTTP1"  # HTTP1, HTTP2, GRPC
            # if Type = "ip"
            ip_address_type = null
            
            #ALB Option
            deregistration_delay = 300
            slow_start = 0
            load_balancing_algorithm_type = "round_robin"   # round_robin or least_outstanding_requests

            st_enabled = false
            st_cookie_name = null#"test-cookie"
            st_cookie_duration = null#86400          # 1 ~ 604800
            st_type = null#"lb_cookie"               # lb_cookie, app_cookie

            hc_enabled = true
            hc_port = "traffic-port"            # 1-65535, or traffic-port. Defaults to traffic-port.
            hc_protocol = "HTTP"                # 
            healthy_threshold = 5
            unhealthy_threshold = 2
            hc_interval = 30
            hc_timeout = 5
            hc_path = "/"
            hc_matcher = "200"

            tags = {
                #Environment = "production"
                Name = "tg-${local.proj_name}-${local.proj_env}-${local.proj_region}-proto-80"
            }
        }
    ]

    listener = [
        {
            lb_name = ""
            port              = "443"
            protocol          = "HTTPS"
            ssl_policy        = "ELBSecurityPolicy-2016-08"
            certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
            #target_group_arn = aws_lb_target_group.front_end.arn
        }
    ]
}

###############################################################

/*
dependency "vpc" {
    config_path = "../vpc"
}

dependency "rds" {
    config_path = "../rds"
}

dependencies {
    paths = ["../vpc", "../rds"]
}

inputs = {
    vpc_id = dependency.vpc.outputs.vpc_id
    db_url = dependency.rds.outputs.db_url
}
*/