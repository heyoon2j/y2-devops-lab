output "vpc" {
    description = "VPC Information"
    sensitive = true

    value = {
        id = aws_vpc.vpc_main.id
        name = "${var.vpc_name}"
    }
}


output "public_subnet" {
    description = "Subnet ID"
    sensitive = false

    value = tomap({
        for k, g in aws_subnet.sbn_pub : k => g.id
    })
}

output "private_subnet" {
    description = "Subnet ID"
    sensitive = false

    value = tomap({
        for k, g in aws_subnet.sbn_pri : k => g.id
    })
}

output "attachment_subnet" {
    description = "Information for TGW"
    sensitive = true
    value = [for s in data.aws_subnet.tgw_attahment : s.id]
}


