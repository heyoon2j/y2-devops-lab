locals {
    vpcs = {
        dmz_vpc = {
            name                = "vpc-dmz-crawling"
            cidr_block          = "172.16.0.0/16"
            instance_tenancy    = "default"
            enable_dns_support    = true
            enable_dns_hostnames  = true
            enable_network_address_usage_metrics = false
            tags            = {}

            igw = {}
            rt_pub = {
                rt-pub-untrust = {
                    name    = "rt-pub-untrust"
                    tags    = {}
                }
            }

            sbn_pub     = {
                sbn-pub-untrust-a1 = {
                    name                = "sbn-pub-untrust-a1"
                    cidr_block          = "172.16.0.0/24"
                    #ipv6_cidr_block = optional(string, null)
                    availability_zone   = "ap-northeast-2a"
                    route_table         = "rt-pub-untrust"
                    #assign_ipv6_address_on_creation = optional(bool, false)
                    #map_public_ip_on_launch = optional(bool, true)
                    tags    = {}
                }
                sbn-pub-untrust-c1 = {
                    name                = "sbn-pub-untrust-c1"
                    cidr_block          = "172.16.1.0/24"
                    availability_zone   = "ap-northeast-2c"
                    route_table         = "rt-pub-untrust"
                    tags    = {}
                }
            }

            rt_pri = {
                rt-pri-trust = {
                    name    = "rt-pri-trust"
                    tags    = {}
                }
            }

            sbn_pri     = {
                sbn-pri-trust-a1 = {
                    name                = "sbn-pri-trust-a1"
                    cidr_block          = "172.16.2.0/24"
                    availability_zone   = "ap-northeast-2a"
                    route_table         = "rt-pri-trust"
                    tags    = {}
                }
                sbn-pri-trust-c1 = {
                    name                = "sbn-pri-trust-c1"
                    cidr_block          = "172.16.3.0/24"
                    availability_zone   = "ap-northeast-2c"
                    route_table         = "rt-pri-trust"
                    tags    = {}
                }
            }
        }
    }
}