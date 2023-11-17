/*
# Network Firewall
1. Firewall Policy
    1) 
    2) 
2. Firewall
    1) Routing Table 생성
    2) Routing Table Association
    3) Routing Table의 Route 추가

*/


## Input Value



## Outpu Value


###########################################################
/*abcd
locals {
    pub_rt_cnt = var.pub_rt != 0 ? length(var.pub_rt) : 0
    pri_rt_cnt = var.pri_rt != 0 ? length(var.pri_rt) : 0
    azs_cnt = var.use_azs != null ? length(var.use_azs) : 1
}
abcd*/


############################################################
# 1. Firewall
/*
'Firewall Resource'

Args:
name - (Required, Forces new resource) A friendly name of the firewall.

vpc_id - (Required, Forces new resource) The unique identifier of the VPC where AWS Network Firewall should create the firewall.

delete_protection - (Optional) A boolean flag indicating whether it is possible to delete the firewall. Defaults to false.

description - (Optional) A friendly description of the firewall.

encryption_configuration - (Optional) KMS encryption configuration settings. See Encryption Configuration below for details.
    - type : CUSTOMER_KMS / AWS_OWNED_KMS_KEY
    - key_id : 
firewall_policy_arn - (Required) The Amazon Resource Name (ARN) of the VPC Firewall policy.

firewall_policy_change_protection - (Option) A boolean flag indicating whether it is possible to change the associated firewall policy. Defaults to false.

subnet_change_protection - (Optional) A boolean flag indicating whether it is possible to change the associated subnet(s). Defaults to false.

subnet_mapping - (Required) Set of configuration blocks describing the public subnets. Each subnet must belong to a different Availability Zone in the VPC. AWS Network Firewall creates a firewall endpoint in each subnet. See Subnet Mapping below for details.
    - ip_address_type : "DUALSTACK", "IPV4"
    - subnet_id : 
tags - (Optional) Map of resource tags to associate with the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.

*/

resource "aws_networkfirewall_firewall" "nfw_firewall" {
    name                = var.firewall["name"]
    vpc_id              = var.firewall["vpc_id"]

    dynamic subnet_mapping {
        for_each = var.firewall["subnet_mapping"]

        content {
            subnet_id = subnet_mapping.value["subnet_id"]
            #ip_address_type = subnet_mapping.value["ip_address_type"]
        }
    }
    subnet_change_protection = var.firewall["subnet_change_protection"]
    #encryption_configuration = var.firewall["encryption_configuration"]

    firewall_policy_arn = aws_networkfirewall_firewall_policy.nfw_fw_policy_default.arn #var.firewall["firewall_policy_arn"]
    firewall_policy_change_protection = var.firewall["firewall_policy_change_protection"]

    delete_protection = var.firewall["delete_protection"]

    tags = var.firewall["tags"]
}


/*
Firewall Policy

    - policy_variables : (Optional). Contains variables that you can use to override default Suricata settings in your firewall policy. See Rule Variables for details.

    - stateless_custom_action - (Optional) Set of configuration blocks describing the custom action definitions that are available for use in the firewall policy's stateless_default_actions. See Stateless Custom Action below for details.


    - stateless_default_actions : (Required) Set of actions to take on a packet if it does not match any of the stateless rules in the policy. You must specify one of the standard actions including: aws:drop, aws:pass, or aws:forward_to_sfe. In addition, you can specify custom actions that are compatible with your standard action choice. If you want non-matching packets to be forwarded for stateful inspection, specify aws:forward_to_sfe.
        type = list(string)
        validation { aws:drop, aws:pass, aws:forward_to_sfe }

    - stateless_fragment_default_actions : (Required) Set of actions to take on a fragmented packet if it does not match any of the stateless rules in the policy. You must specify one of the standard actions including: aws:drop, aws:pass, or aws:forward_to_sfe. In addition, you can specify custom actions that are compatible with your standard action choice. If you want non-matching packets to be forwarded for stateful inspection, specify aws:forward_to_sfe.
        type = list(string)
        validation { aws:drop, aws:pass, aws:forward_to_sfe }

    - stateless_rule_group_reference - (Optional) Set of configuration blocks containing references to the stateless rule groups that are used in the policy. See Stateless Rule Group Reference below for details.


    - stateful_engine_options : (Optional) A configuration block that defines options on how the policy handles stateful rules. See Stateful Engine Options below for details.
        type = object(
            rule_order = DEFAULT_ACTION_ORDER (Default), STRICT_ORDER
            stream_exception_policy = DROP (Default), CONTINUE, REJECT.
        )

    - stateful_default_actions : (Optional) Set of actions to take on a packet if it does not match any stateful rules in the policy. This can only be specified if the policy has a stateful_engine_options block with a rule_order value of STRICT_ORDER. You can specify one of either or neither values of aws:drop_strict or aws:drop_established, as well as any combination of aws:alert_strict and aws:alert_established.
        type = list(string)
        validation { aws:drop_strict, aws:drop_established, aws:alert_strict, aws:alert_established }

    - stateful_rule_group_reference - (Optional) Set of configuration blocks containing references to the stateful rule groups that are used in the policy. See Stateful Rule Group Reference below for details.

*/

resource "aws_networkfirewall_firewall_policy" "nfw_fw_policy_default" {
    name = var.firewall_policy["name"]
    
    firewall_policy {

        #policy_variables = var.firewall_policy["policy_variables"] ? var.firewall_policy["policy_variables"] : null 

        #stateless_custom_action = var.firewall_policy["stateless_custom_action"]
        stateless_default_actions          = var.firewall_policy["stateless_default_actions"]
        stateless_fragment_default_actions = var.firewall_policy["stateless_fragment_default_actions"]
        dynamic stateless_rule_group_reference {
            for_each = var.firewall_policy["stateless_rule_group_reference"]

            content {
                priority     = each.value["priority"]
                resource_arn = each.value["arn"]
            }
        }
        
        #stateful_engine_options = var.firewall_policy["stateful_engine_options"]
        stateful_default_actions = var.firewall_policy["stateful_default_actions"]          
        dynamic stateful_rule_group_reference {
            for_each = var.firewall_policy["stateful_rule_group_reference"]

            content {
                priority     = each.value["priority"]
                resource_arn = each.value["arn"]
            }
        }
    }

    tags = var.firewall_policy["tags"]
}



/*
'Logging Configuration Resource'

Args:
    firewall_arn = aws_networkfirewall_firewall.example.arn
    logging_configuration {
        ...
    }

    ## To S3
    logging_configuration {
        log_destination_config {
            log_destination = {
                bucketName = aws_s3_bucket.example.bucket
                prefix     = "/example"
            }
            log_destination_type = "S3"
            log_type             = "FLOW"
        }
    }

    ## To ClouWatch
    logging_configuration {
        log_destination_config {
            log_destination = {
                logGroup = aws_cloudwatch_log_group.example.name
            }
            log_destination_type = "CloudWatchLogs"
            log_type             = "ALERT"
        }
    }

    ## To Kinesis
    logging_configuration {
        log_destination_config {
            log_destination = {
                deliveryStream = aws_kinesis_firehose_delivery_stream.example.name
            }
            log_destination_type = "KinesisDataFirehose"
            log_type             = "ALERT"
        }
    }

*/

resource "aws_networkfirewall_logging_configuration" "nfw_log_config" {
    count = var.firewall["logging_configuration"] != null ? 1 : 0

    firewall_arn = aws_networkfirewall_firewall.nfw_firewall.arn
    logging_configuration {
        log_destination_config {
            log_destination = {
                    bucketName = "abcde"
                    prefix     = "/example"
            }
            log_destination_type = "S3"
            log_type             = "FLOW"
        }
    }
}

