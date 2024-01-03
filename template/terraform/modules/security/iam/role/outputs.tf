output "role_name" {
    description = "Role Name"
    value = aws_iam_role.main.name
}

output "role_id" {
    description = "Role ID"
    sensitive = true
    value = aws_iam_role.main.id
}

output "role_arn" {
    description = "Role ARN"
    sensitive = true
    value = aws_iam_role.main.arn
}