locals {
    user_data = ""
    default_tags = {}


    instances = {
        test_instance = {
            name            = "test_instance"
            instance_type   = "t2-small"
            image_name      = ""
            #key_name        = optional(string, null)

            # Network
            subnet_name                 = ""
            sg_names                    = [""]
            #source_dest_check           = optional(bool, true)
            ## Static or Dynamic IP
            #private_ip_static_enabled   = optional(bool, false)
            #private_ip_static_list      = optional(list(string), null)
            private_ip_dynamic          = 1
            ## Place Group
            #placement_group         = optional(string, null)
            #placement_partition_number = optional(string, null)

            # Option
            #tenancy                 = optional(string, "default")
            #disable_api_termination = optional(bool, true)
            #disable_api_stop        = optional(bool, false)
            #instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"

            # Option - Neccessary
            ## Metadata
            #http_endpoint   = optional(string, "enabled")   # "enabled", "disabled"
            #http_tokens     = optional(string, "required")  # "required", "optional"
            #http_put_response_hop_limit = optional(number, 2)
            #instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
            ## 
            user_data                   = local.user_data
            default_tags                = local.default_tags
            #tags                        = optional(map(string), null)
        }
    }

    sg = {

    }
}

module "sg_test" {
    provider = aws.cloud-poc-apn2
    source = "./modules_v2/computing/sg"
    profile = aws.common-poc

    for_each = local.sg



}



module "ec2" {
    provider = local.provider_cfg
    source = "./modules_v2/computing/instance"
    profile = ""

    for_each = local.instances

    ec2_instnace = each.value
/*
    description     = each.value.description
    name            = each.value.name
    instance_type   = each.value.instance_type
    image_name      = each.vlaue.image_name
    key_name        = each.value.key_name

    # Network
    subnet_name                 = each.value.subnet_name
    sg_names                    = each.value.sg_names
    source_dest_check           = each.value.source_dest_check
    ## Static or Dynamic IP
    private_ip_static_enabled   = each.value.private_ip_static_enabled
    private_ip_static_list      = each.value.private_ip_static_list
    private_ip_dynamic          = each.value.private_ip_dynamic
    ## Place Group
    placement_group             = each.value.placement_group
    placement_partition_number  = each.value.placement_partition_number

    # Option
    tenancy                 = each.value.tenancy
    disable_api_termination = each.value.disable_api_termination
    disable_api_stop        = each.value.disable_api_stop
    instance_initiated_shutdown_behavior    = each.value.instance_initiated_shutdown_behavior

    # Option - Neccessary
    ## Metadata
    http_endpoint               = each.value.http_endpoint
    http_tokens                 = each.value.http_tokens
    http_put_response_hop_limit = each.value.http_put_response_hop_limit
    instance_metadata_tags      = each.value.instance_metadata_tags
    ## Default options
    user_data                   = each.value.user_data
    default_tags                = each.value.default_tags
    tags                        = each.value.tags
*/
}