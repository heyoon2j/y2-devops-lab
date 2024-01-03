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
    source = "${get_parent_terragrunt_dir("root")}//modules/computing/nlb"
}

inputs = {
    vpc_id = dependency.secure_vpc.outputs.vpc["id"]


# NLB
    nlb = [
        {
            name = "nlb-${local.proj_name}-${local.proj_env}-ec2-readOnly"
            internal = true
            load_balancer_type = "network"
            subnets = ["sbn-${local.proj_name}-${local.proj_env}-${local.proj_region}-a-pub-untrust", "sbn-${local.proj_name}-${local.proj_env}-${local.proj_region}-b-pub-untrust"]
            ip_address_type = "ipv4"
            security_groups = ["${local.proj_name}-${local.proj_env}-http-sg"]

            enable_deletion_protection = false

            # NLB Option
            enable_cross_zone_load_balancing = false

            log_enabled = false
            log_bucket  = null
            log_prefix  = null

            tags = {
                Name = "nlb-${local.proj_name}-${local.proj_env}-ec2-readOnly"
                Test = "test"
            }            
        }
    ]

    targetGroup = [
        {
            name     = "tg-${local.proj_name}-${local.proj_env}-${local.proj_region}-proto-8080"
            target_type = "instance"    # "instance", "ip", "lambda", "alb"
            port     = 8080
            protocol = "TCP"           # GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS, UDP
            # if Type = "ip"
            ip_address_type = null
 
            deregistration_delay = 300

            #NLB Option
            connection_termination = true
            preserve_client_ip = true
            proxy_protocol_v2 = false

            st_enabled = false
            st_type = "source_ip"                    # "source_ip"

            hc_enabled = true
            hc_port = "traffic-port"            # 1-65535, or traffic-port. Defaults to traffic-port.
            hc_protocol = "TCP"                # TCP, HTTP, HTTPS
            healthy_threshold = 3
            unhealthy_threshold = 3
            hc_interval = 30
            hc_timeout = null

            tags = {
                #Environment = "production"
                Name = "tg-${local.proj_name}-${local.proj_env}-${local.proj_region}-proto-80"
            }
        },
        {
            name     = "tg-${local.proj_name}-${local.proj_env}-${local.proj_region}-proto-8090"
            target_type = "ip"    # "instance", "ip", "lambda", "alb"
            port     = 8090
            protocol = "TCP"           # GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS, UDP
             # if Type = "ip"
            ip_address_type = "ipv4"        # "ipv4", "ipv6"
 
            deregistration_delay = 300

            #NLB Option
            connection_termination = true
            preserve_client_ip = true
            proxy_protocol_v2 = false

            st_enabled = false
            st_type = null                     # "source_ip"

            hc_enabled = true
            hc_port = "traffic-port"            # 1-65535, or traffic-port. Defaults to traffic-port.
            hc_protocol = "TCP"                # TCP, HTTP, HTTPS
            healthy_threshold = 3
            unhealthy_threshold = 3
            hc_interval = 30
            hc_timeout = null

            tags = {
                #Environment = "production"
                Name = "tg-${local.proj_name}-${local.proj_env}-${local.proj_region}-proto-8090"
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