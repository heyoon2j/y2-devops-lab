output "policy_anr_custom" {
    description = "Policy - Custiom"
    sensitive = true
    value = {
        for k, v in aws_iam_policy.custom: k => v.arn
    }
}

output "policy_arn_boundary" {  
    description = "Policy for boundary"
    sensitive = true
    value = {
        for k, v in aws_iam_policy.boundary: k => v.arn
    }
}