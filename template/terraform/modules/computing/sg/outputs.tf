output "sg" {
    description = "Security Group Information"
    sensitive = true

    value = [
        for s in aws_security_group.sg-proj:
            {
                "name" = s.tags_all["Name"]
                "id" = s.id
                "arn" = s.arn
            }
    ]
}
