output "policy_custom_arn" {
    description = "Policy - Custiom"
    sensitive = true
    value = {
        for k, v in aws_iam_policy.policy_custom: k => v.arn
    }
}

output "policy_boundary_arn" {  
    description = "Policy for boundary"
    sensitive = true
    value = {
        for k, v in aws_iam_policy.policy_boundary: k => v.arn
    }
}