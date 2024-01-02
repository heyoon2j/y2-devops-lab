# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VPC
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

output "vpc_id" {
    description = "VPC Information"
    sensitive = true
    value = try(aws_vpc.main.id, null)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

output "sbn_pub" {
    description = "Public Subnet ID"
    sensitive = false

    value = tomap({
        for k, v in aws_subnet.public : k => v.id
    })
}

output "sbn_pri" {
    description = "Private Subnet ID"
    sensitive = false

    value = tomap({
        for k, v in aws_subnet.private : k => v.id
    })
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# TGW Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

output "tgw_attachment_subnet" {
    description = "Information for TGW"
    sensitive = true
    value = [for s in data.aws_subnet.tgw_attahment : s.id]
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "rt_pub" {
    description = "Public Route Table ID"
    sensitive = false

    value = tomap({
        for k, v in aws_route_table.public : k => v.id
    })
}

output "rt_pri" {
    description = "Private Route Table ID"
    sensitive = false

    value = tomap({
        for k, v in aws_route_table.private : k => v.id
    })
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Internet Gateway 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "igw_id" {
    description = "Internet Gateway ID"
    sensitive = false

    value = length(aws_internet_gateway.this) != 0 ? aws_internet_gateway.this[0].id : null
}
