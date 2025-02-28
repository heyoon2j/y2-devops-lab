locals {
    vpcs = {
        dmz_vpc = {
            name            = "vpc-dmz-crawling"
            cidr_block          = "172.16.0.0/16"
            # instance_tenancy      = 
            # enable_dns_support    =
            # enable_dns_hostnames    =
            # enable_network_address_usage_metrics = 
            tags            = {}

            igw = {}
            # {
            #     name = "igw-dmz-crawling"
            #     tags = {}
            # }

            rt_pub = {
                rt_pub_untrut = {
                    name    = "rt-pub-untrust"
                    tags    = {}
                }
            }

            sbn_pub     = {
                sbn_pub_untrust_a1 = {
                    name                = "sbn-pub-untrust-a1"
                    cidr_block          = "172.16.0.0/24"
                    #ipv6_cidr_block = optional(string, null)
                    availability_zone   = "ap-northeast-2a"
                    route_table         = "rt-pub-untrust"
                    #assign_ipv6_address_on_creation = optional(bool, false)
                    #map_public_ip_on_launch = optional(bool, true)
                    tags    = {}
                }
                sbn_pub_untrust_c1 = {
                    name                = "sbn-pub-untrust-c1"
                    cidr_block          = "172.16.1.0/24"
                    availability_zone   = "ap-northeast-2c"
                    route_table         = "rt-pub-untrust"
                    tags    = {}
                }
            }

            rt_pri = {
                rt_pri_trust = {
                    name    = "rt-pri-trust"
                    tags    = {}
                }
            }

            sbn_pri     = {
                sbn_pri_trust_a1 = {
                    name                = "sbn-pri-trust-a1"
                    cidr_block          = "172.16.2.0/24"
                    availability_zone   = "ap-northeast-2a"
                    route_table         = "rt-pri-trust"
                    tags    = {}
                }
                sbn_pri_trust_c1 = {
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