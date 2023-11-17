output "zone" {
    description = "Hosted Zone Information"
    sensitive = true

    value = {
        id = aws_route53_zone.hosted_zone.zone_id
        arn = aws_route53_zone.hosted_zone.arn
    }
}
