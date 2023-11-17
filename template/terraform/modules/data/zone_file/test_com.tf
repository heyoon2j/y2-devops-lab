data "aws_route53_zone" "selected" {
    filter {
        name   = "tag:Name"
        values = ["test.com"]
    }
}

resource "aws_route53_record" "www" {
    zone_id = data.aws_route53_zone.selected.zone_id
    name    = "www.test.com"
    type    = "A"
    ttl     = 300
    records = ["10.20.30.40"]
}

##################################