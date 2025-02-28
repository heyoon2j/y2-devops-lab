
module "vpc" {
    providers = {
        aws = aws.common-poc-apn2
    }
    source = "../modules_v2/networking/instance"

    for_each = local.vpcs
    
    name        = each.value.name
    cidr_block  = each.value.cidr_block

    instance_tenancy        = each.value.tenancy
    enable_dns_support      = each.value.enable_dns_support
    enable_dns_hostnames    = each.value.enable_dns_hostnames

    # enable_network_address_usage_metrics = 
    tags        = each.value.tags

    igw         = each.value.igw

    sbn_pub     = each.value.sbn_pub
    rt_pub      = each.value.rt_pub
    sbn_pri     = each.value.sbn_pri
    rt_pri      = each.value.rt_pri
}

# module "subnet" {
#     providers = {
#         aws = aws.common-poc-apn2
#     }

#     source = "../modules_v2/networking/subnet"

#     for_each = local.vpcs
    
#     name    = each.value.name

# } 

