output "zone" {
    description = "Hosted Zone Information"
    sensitive = true

    value = {
        id = aws_route53_zone.main.zone_id
        arn = aws_route53_zone.main.arn
    }
}
