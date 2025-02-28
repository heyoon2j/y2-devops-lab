# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

output "sbn" {
    description = "Subnet ID"
    sensitive = false

    value = tomap({
        for k, v in aws_subnet.this : k => v.id
    })
}

/*
output "sbn_pri" {
    description = "Private Subnet ID"
    sensitive = false

    value = tomap({
        for k, v in aws_subnet.private : k => v.id
    })
}
*/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Route Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "rt" {
    description = "Route Table ID"
    sensitive = false

    value = tomap({
        for k, v in aws_route_table.this : k => v.id
    })
}
/*
output "rt_pri" {
    description = "Private Route Table ID"
    sensitive = false

    value = tomap({
        for k, v in aws_route_table.private : k => v.id
    })
}
*/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Internet Gateway 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "igw_id" {
    description = "Internet Gateway ID"
    sensitive = false

    value = length(aws_internet_gateway.this) != 0 ? aws_internet_gateway.this[0].id : null
}
