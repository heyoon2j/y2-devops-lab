
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

            stateful_rule {
                action = "DROP"
                header {
                    destination      = "124.1.1.24/32"
                    destination_port = 53
                    direction        = "ANY"
                    protocol         = "TCP"
                    source           = "1.2.3.4/32"
                    source_port      = 53
                }
                rule_option {
                    keyword  = "sid"
                    settings = ["1"]
                }
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
