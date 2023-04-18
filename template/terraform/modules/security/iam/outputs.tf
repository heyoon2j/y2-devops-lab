output "role" {
    description = "VPC Information"
    sensitive = true

    value = [
        for r in aws_iam_role.role-proj:
            {
                "name" = r.name
                "id" = r.id
                "arn" = r.arn
            }
    ]
}

output "user_policy" {
    description = "Policy by user"
    sensitive = true
    value = [
        for policy in aws_iam_policy.policy-user-proj:
            {
                "name" = policy.name
                "id" = policy.id
                "arn" = policy.arn
            }
    ]
}

