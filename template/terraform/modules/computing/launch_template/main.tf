#############################################################################################
/*
# Launch Template Configuration
*/
#############################################################################################

resource "aws_launch_template" "main" {
    # # # # # # # Common # # # # # # #
    name =                  # string
    description =           # optional(string, null)
    default_version =       # number
    #update_default_version - (Optional) Whether to update Default Version each update. Conflicts with default_version.
    tags =                  # optional(map(any), null)

    # # # # # # # Compute # # # # # # #
    image_id =              # string
    instance_type =         # optional(string, "t2.micro")

    # # # # # # # Network # # # # # # #
    
    # network_interfaces {}
    # security_group_names = null
    # private_dns_name_options = null
    # vpc_security_group_ids = null

    # # # # # # # Storage # # # # # # #
    ebs_optimized = true                   # true or false
    block_device_mappings {
        device_name = "/dev/xvda"      # string 
        #no_device - (선택 사항) AMI의 블록 장치 매핑에 포함된 지정된 장치를 억제합니다.
        #virtual_name
        ebs {
            snapshot_id =           # optional(string, null)
            volume_type = "gp3"     # standard, gp2, gp3, io1, io2, sc1, st1
            volume_size = 10        # number (GiB)
            iops = 3000             # number (When volume_type is "io1/io2/gp3")
            throughput = 125        # number (When volume_type is "io1/io2/gp3") 
            delete_on_termination = # true or false 
            encrypted = true
            kms_key_id =            # string
        }
    }
    block_device_mappings {
        device_name = "/dev/sd[fp]"      # string 
        #no_device - (선택 사항) AMI의 블록 장치 매핑에 포함된 지정된 장치를 억제합니다.
        #virtual_name
        ebs {
            snapshot_id =           # optional(string, null)
            volume_type = "gp2"     # standard, gp2, gp3, io1, io2, sc1, st1
            volume_size = 10        # number
            iops = null             # number (When volume_type is "io1/io2/gp3")
            throughput = null       # number (When volume_type is "io1/io2/gp3") 
            delete_on_termination = # true or false 
            encrypted = true
            kms_key_id =            # string
        }
    }

    # # # # # # # Option - 0 (Required) # # # # # # #
    key_name =                      # string
    iam_instance_profile {
        #arn = optional(string, null)
        name = "role-temp"
    }
    instance_initiated_shutdown_behavior = "stop"       # stop or terminate
    disable_api_stop = false                            # true or false 
    disable_api_termination = false                     # true or false 
    maintenance_options {
        auto_recovery = "default"           # "default" or "disabled
    }
    monitoring {
        enabled = false
    }
    metadata_options{
        http_endpoint = "enabled"           # enabled or disabled (Default: "enabled")
        http_tokens = "required"            # required or optional (Default: "optional")
        http_put_response_hop_limit = 1     # 1 ~ 64 (Default: 1)
        instance_metadata_tags = "enabled"  # enabled or disabled
        #http_protocol_ipv6 = # enabled or disabled
    }
    user_data =                 # optional(string, null)
    tag_specifications {
        resource_type = "instance"    # nstance | volume | elastic-gpu | network-interface | spot-instances-request
        tags = {}
    }
    tag_specifications {
        resource_type = "volume"
        tags = {}
    }
    tag_specifications {
        resource_type = "network-interface"
        tags = {}
    }

    # # # # # # # Option - 1 (Optional) # # # # # # #
    /*
    capacity_reservation_specification - (Optional) Targeting for EC2 capacity reservations. See Capacity Reservation Specification below for more details.
    cpu_options - (Optional) The CPU options for the instance. See CPU Options below for more details.
    credit_specification - (Optional) Customize the credit specification of the instance. See Credit Specification below for more details.

    elastic_gpu_specifications - (Optional) The elastic GPU to attach to the instance. See Elastic GPU below for more details.
    elastic_inference_accelerator - (Optional) Configuration block containing an Elastic Inference Accelerator to attach to the instance. See Elastic Inference Accelerator below for more details.
    enclave_options - (Optional) Enable Nitro Enclaves on launched instances. See Enclave Options below for more details.
    hibernation_options - (Optional) The hibernation options for the instance. See Hibernation Options below for more details.

    instance_market_options - (Optional) The market (purchasing) option for the instance. See Market Options below for details.
    instance_requirements - (Optional) The attribute requirements for the type of instance. If present then instance_type cannot be present.

    kernel_id - (Optional) The kernel ID.
    ram_disk_id - (Optional) The ID of the RAM disk.

    license_specification - (Optional) A list of license specifications to associate with. See License Specification below for more details.

    placement - (Optional) The placement of the instance. See Placement below for more details.
    */
}

/*
resource "aws_launch_template" "main" {
    name = var.launch_temp.template_name

    # AMI
    image_id = var.launch_temp.image_id

    # Instance Type
    #instance_type = var.launch_temp.instance_type

    # Key Pair
    key_name = var.launch_temp.key_name


    # Network 
    network_interfaces {
        associate_public_ip_address = var.launch_temp.associate_public_ip_address
    }    

    vpc_security_group_ids = var.launch_temp.vpc_security_group_ids


    # Volume
    dynamic "block_device_mappings" {
        for_each = var.launch_temp.block_device_mappings

        content {
            device_name = block_device_mappings.value["device_name"]
            ebs {
                volume_size = block_device_mappings.value["volume_size"]
                volume_type = block_device_mappings.value["volume_type"] 
                iops = block_device_mappings.value["iops"]
                throughput = block_device_mappings.value["throughput"]

                delete_on_termination = block_device_mappings.value["delete_on_termination"] 
                encrypted = block_device_mappings.value["encrypted"]

                kms_key_id = block_device_mappings.value["kms_key_id"]
            }
        }
    }

    # Option

    dynamic "iam_instance_profile" {
        for_each = var.launch_temp.iam_instance_profile

        content {
            name = iam_instance_profile.value
        }
    }

    private_dns_name_options {
        hostname_type = var.launch_temp.private_dns_name_options.hostname_type 
        enable_resource_name_dns_a_record = var.launch_temp.private_dns_name_options.enable_resource_name_dns_a_record
    }

    instance_initiated_shutdown_behavior = var.launch_temp.instance_initiated_shutdown_behavior

    hibernation_options {
        configured = var.launch_temp.hibernation_options.configured
    }

    disable_api_stop = var.launch_temp.disable_api_stop
    disable_api_termination = var.launch_temp.disable_api_termination


    monitoring {
        enabled = var.launch_temp.monitoring.enabled
    }

    ebs_optimized = var.launch_temp.ebs_optimized


    metadata_options {
        http_endpoint               = var.launch_temp.metadata_options.http_endpoint
        http_tokens                 = var.launch_temp.metadata_options.http_tokens
        http_put_response_hop_limit = var.launch_temp.metadata_options.http_put_response_hop_limit
        instance_metadata_tags      = var.launch_temp.metadata_options.instance_metadata_tags
    }

    user_data = var.launch_temp.user_data

    dynamic "tag_specifications" {
        for_each = var.launch_temp.tag_specifications

        content {
            resource_type = each.key
            tags = each.value
        }
    }

    credit_specification {
        cpu_credits = "standard"
    }
    placement {
        availability_zone = "us-west-2a"
    }
    capacity_reservation_specification {
        capacity_reservation_preference = "open"
    }
    kernel_id = "test"
    ram_disk_id = "test"
    cpu_options {
        core_count       = 4
        threads_per_core = 2
    }
    elastic_gpu_specifications {
        type = "test"
    }
    elastic_inference_accelerator {
        type = "eia1.medium"
    }
    license_specification {
        license_configuration_arn = "arn:aws:license-manager:eu-west-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
    }   
}
*/