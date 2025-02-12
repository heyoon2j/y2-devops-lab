#############################################################################################
/*
# Security Group Configuration
1. Security Group
2. Ingress Rule
3. Egress Rule
*/
#############################################################################################

locals {
}

variable "ec2_instance" {
    description = "EC2 Instance Variable"
    # default = 
    type = map(object({
        description = optional(string, null)

        instance_name   = string
        instance_type   = string
        image_name      = string
        key_name        = optional(string, null)

        # Network
        subnet_name                 = string
        sg_names                    = list(string)
        source_dest_check           = optional(bool, true)
        ## Static or Dynamic IP
        private_ip_static_enabled   = optional(bool, false)
        private_ip_static_list      = optional(list(string), null)
        private_ip_dynamic          = optional(number, 0)
        ## Place Group
        placement_group         = optional(string, null)
        placement_partition_number = optional(string, null)

        # Option
        tenancy                 = optional(string, "default")
        disable_api_termination = optional(bool, true)
        disable_api_stop        = optional(bool, false)
        instance_initiated_shutdown_behavior    = optional(string, "stop")  # "stop"

        # Option - Neccessary
        ## Metadata
        http_endpoint   = optional(string, "enabled")   # "enabled", "disabled"
        http_tokens     = optional(string, "required")  # "required", "optional"
        http_put_response_hop_limit = optional(number, 2)
        instance_metadata_tags      = optional(string, "enabled")    # "disabled", "enabled"
        ## 
        user_data                   = optional(string, null)
        default_tags                = optional(map(string), null)
        tags                        = optional(map(string), null)
    }))

}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Data Resource (Name---> ID)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
data "aws_ami" "selected" {
    for_each    = var.ec2_instance
    most_recent = true

    filter {
        name   = "name"
        values = [each.value.image_name]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}


# subnet name
data "aws_subnet" "selected" {
    for_each = var.ec2_instance

    filter {
        name   = "tag:Name"
        values = [each.value.subnet_name]
    }
}

# Security Groups
data "aws_security_groups" "selected" {
    for_each = var.ec2_instance

    filter {
        name   = "group-names"
        values = each.value.sg_names
    }
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Network Interface
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "aws_network_interface" "this" {
    for_each    = var.ec2_instance

    subnet_id   = data.aws_subnet.selected[each.key].id
    security_groups = data.aws_security_group.selected[each.key]

    private_ip_list_enabled = each.value.private_ip_list_enabled

    private_ip_list         = each.value.private_ip_list_enabled ? each.value.private_ip_list : null
    private_ips_count       = each.value.private_ip_list_enabled ? null : each.value.private_ips_count    

    source_dest_check = each.value.source_dest_check

    tags              = merge(
        {
            "Name"    = each.value.instance_name
        },
        each.value.default_tags
    )
}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. EC2 Instance
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "ec2_instance" "this" {
    for_each        = var.ec2_instance

    instance_name   = each.value.instance_name

    instance_type   = each.value.instance_type
    ami             = data.aws_ami.selected[each.key].id
    key_name        = each.value.key_name

    # Network
    network_interface {
        network_interface_id = aws_network_interface.this[each.key].id
        device_index         = 0
    }


    placement_group                 = each.value.placement_group
    placement_partition_number      = each.value.placement_partition_number

    # Option
    tenancy                                 = each.value.tenancy
    disable_api_termination                 = each.value.disable_api_termination
    disable_api_stop                        = each.value.disable_api_stop
    instance_initiated_shutdown_behavior    = each.value.instance_initiated_shutdown_behavior

    # Option - Neccessary
    ## Metadata
    http_endpoint               = each.value.http_endpoint
    http_tokens                 = each.value.http_tokens
    http_put_response_hop_limit = each.value.http_put_response_hop_limit
    instance_metadata_tags      = each.value.instance_metadata_tags
    user_data                   = each.value.user_data
    tags                        = merge(
        each.value.default_tags,
        {
            "Name"    = each.value.instance_name
        },
        each.value.tags
    )
}