output "launch_template_id" {
    description = "Launch Template ID"
    value = aws_launch_template.main.id
    # value = aws_launch_template.main.arn
}
