# EC2 Launch Template


resource "aws_launch_template" "tempate_ami" {
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

/*
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
*/
    
}