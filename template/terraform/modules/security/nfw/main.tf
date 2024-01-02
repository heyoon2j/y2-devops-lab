#############################################################################################
/*
# Network Firewall Configuration
1. Firewall policies
2. Firewall
3. Firewall Logging Configuation
    - S3
    - CloudWatch
    - Kinesis

4. Network Firewall rule groups (in other module)
*/
#############################################################################################

locals {
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Firewall policies
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
/*
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


resource "aws_networkfirewall_firewall_policy" "default" {
    name                        = var.firewall_policy["name"]
    description                 = var.firewall_policy["description"]
    #encryption_configuration    = var.firewall_policy["encryption_configuration"]
    firewall_policy {
        # policy_variables {
        #     dynamic "rule_variables" {
        #         for_each = var.firewall_policy["policy_variables"]
                
        #         content {
        #             key = rule_variables.value["key"]
        #             ip_set {
        #                 definition = rule_variables.value["ip_set"]
        #             }
        #         }
        #     }
        # }
        stateless_default_actions          = var.firewall_policy["stateless_default_actions"]
        stateless_fragment_default_actions = var.firewall_policy["stateless_fragment_default_actions"]
        dynamic "stateless_rule_group_reference" {
            for_each = var.firewall_policy["stateless_rule_group_reference"]

            content {
                priority     = stateless_rule_group_reference.value["priority"]
                resource_arn = stateless_rule_group_reference.value["arn"]
            }
        }
        #stateless_custom_action = var.firewall_policy["stateless_custom_action"]
        stateful_engine_options {
            rule_order              = var.firewall_policy["stateful_engine_options"]["rule_order"]
            #stream_exception_policy = var.firewall_policy["stateful_engine_options"]["stream_exception_policy"]
        } 
        stateful_default_actions = var.firewall_policy["stateful_engine_options"] == "STRICT_ORDER" ? var.firewall_policy["stateful_default_actions"] : null
        dynamic "stateful_rule_group_reference" {
            for_each = var.firewall_policy["stateful_rule_group_reference"]

            content {
                priority     = stateful_rule_group_reference.value["priority"]
                resource_arn = stateful_rule_group_reference.value["arn"]
            }
        }
    }
    tags = var.firewall_policy["tags"]
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. Firewall
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_networkfirewall_firewall" "main" {
    name                = var.firewall["name"]
    description         = var.firewall["description"]
    vpc_id              = var.firewall["vpc_id"]

    delete_protection = var.firewall["delete_protection"]

    dynamic subnet_mapping {
        for_each = var.firewall["subnet_mapping"]

        content {
            subnet_id = subnet_mapping.value["subnet_id"]
            #ip_address_type = subnet_mapping.value["ip_address_type"]
        }
    }
    subnet_change_protection = var.firewall["subnet_change_protection"]
    #encryption_configuration = var.firewall["encryption_configuration"]

    firewall_policy_arn = aws_networkfirewall_firewall_policy.default.arn #var.firewall["firewall_policy_arn"]
    firewall_policy_change_protection = var.firewall["firewall_policy_change_protection"]

    tags = var.firewall["tags"]
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Firewall Logging Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## S3
resource "aws_networkfirewall_logging_configuration" "s3_flow" {
    count = (var.log_destination_type == "S3") ? 1 : 0

    firewall_arn = aws_networkfirewall_firewall.main.arn
    logging_configuration {
        dynamic log_destination_config {
            for_each = var.firewall_logging

            content {
                log_destination_type = var.log_destination_type
                log_destination = {
                    bucketName = log_destination_config.value["log_destination"]["bucketName"]
                    prefix     = log_destination_config.value["log_destination"]["prefix"]
                }
                log_type             = log_destination_config.value["log_type"]
            }
        }
    }
}

## CloudWatch Logs
resource "aws_networkfirewall_logging_configuration" "cloudwatchlogs_flow" {
    count = (var.log_destination_type == "CloudWatchLogs") ? 1 : 0

    firewall_arn = aws_networkfirewall_firewall.main.arn
    logging_configuration {
        dynamic log_destination_config {
            for_each = var.firewall_logging

            content {
                log_destination_type = var.log_destination_type
                log_destination = {
                    logGroup = log_destination_config.value["log_destination"]["logGroup"]
                }
                log_type             = log_destination_config.value["log_type"]
            }
        }
    }
}

## Kinesis
resource "aws_networkfirewall_logging_configuration" "kinesis_flow" {
    count = (var.log_destination_type == "KinesisDataFirehose") ? 1 : 0

    firewall_arn = aws_networkfirewall_firewall.main.arn
    logging_configuration {
        dynamic log_destination_config {
            for_each = var.firewall_logging

            content {
                log_destination_type = var.log_destination_type
                log_destination = {
                    deliveryStream = log_destination_config.value["log_destination"]["deliveryStream"]
                }
                log_type             = log_destination_config.value["log_type"]
            }
        }
    }
}