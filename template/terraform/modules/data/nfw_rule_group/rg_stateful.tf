
resource "aws_networkfirewall_rule_group" "nfw_rg_stateful" {
    name     = "example"
    type     = "STATEFUL"
    capacity = 100

    rule_group {
        rules_source {
            rules_source_list {
                generated_rules_type = "DENYLIST"
                target_types         = ["HTTP_HOST"]
                targets              = ["test.example.com"]
            }
        }
    }

    tags = {
        Tag1 = "Value1"
        Tag2 = "Value2"
    }
}


output "stateful_rule_group" {  
    description = "Stateful Rule Group"
    sensitive = true
    value = {
    for rule_group in aws_networkfirewall_rule_group.nfw_rg_stateful:
        arn = rule_group.arn
    }
}
