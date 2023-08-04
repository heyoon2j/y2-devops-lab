/*
output "role" {
    description = "VPC Information"
    sensitive = true

    value = {
        for r in aws_iam_role.role-proj:
            {
                "name" = r.name
                "id" = r.id
                "arn" = r.arn
            
    }
}
*/
