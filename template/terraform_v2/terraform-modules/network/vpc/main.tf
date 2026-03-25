resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    enable_dns_hostnames = var.enable_dns_hostnames # true
    enable_dns_support = var.enable_dns_support # true
    instance_tenancy = var.instance_tenancy # "default"
    enable_network_address_usage_metrics = var.enable_network_address_usage_metrics
    # enable_classiclink = "false"
    # enable_classiclink_dns_support = "false"

    tags = merge(
        {
            "Name" = var.name
        },
        var.tags
    )
}