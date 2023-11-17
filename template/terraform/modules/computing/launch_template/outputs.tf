/*
output "sg" {
    description = "Security Group Information"
    sensitive = true

    value = {
        "name" = aws_security_group.sg_main.name
        "id" = aws_security_group.sg_main.id
        "arn" = aws_security_group.sg_main.arn
    }

}
*/
