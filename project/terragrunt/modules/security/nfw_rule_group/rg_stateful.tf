
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