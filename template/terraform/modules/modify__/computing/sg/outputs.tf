output "sg" {
    description = "Security Group Information"
    sensitive = true

    value = {
        "name" = aws_security_group.main.name
        "id" = aws_security_group.main.id
        "arn" = aws_security_group.main.arn
    }
}
