# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "domain" {
    description = "Domain"
    type = string
}

variable "private_zone" {
    description = "Is this zone file for private"
    type = bool
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Optional Variable
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Record
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
data "aws_route53_zone" "selected" {
    name         = "test.com."
    private_zone = true
}

resource "aws_route53_record" "www" {
    zone_id = data.aws_route53_zone.selected.zone_id
    name    = "www.${data.aws_route53_zone.selected.name}"
    type    = "A"
    ttl     = 300
    records = ["10.20.30.40"]
}

##################################