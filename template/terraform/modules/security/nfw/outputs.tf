output "firewall_arn" {
    description = "Firewall Status"
    value = aws_networkfirewall_firewall.main.arn
}
/*
output "policy_custom" {
    description = "Policy - Custiom"
    sensitive = true
    value = {
        for policy in aws_iam_policy.policy_custom:
             = {
                "name" = policy.name
                "id" = policy.id
                "arn" = policy.arn
            }
    }
}

output "policy_boundary" {  
    description = "Policy for boundary"
    sensitive = true
    value = {
        for policy in aws_iam_policy.policy-user-proj:
            {
                "name" = policy.name
                "id" = policy.id
                "arn" = policy.arn
            }
    }
}
*/