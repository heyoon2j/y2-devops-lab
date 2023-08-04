output "vpc" {
    description = "VPC Information"
    sensitive = true

    value = {
        id = aws_vpc.vpc_main.id
        name = "${var.vpc_name}"
    }
}

output "attachment_subnet" {
    description = "Information for TGW"
    sensitive = true
    value = [for s in data.aws_subnet.tgw_attahment : s.id]
}


