# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Endpoint
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "endpoint" {
    description = "Information of endpoint"
    value = tomap({
            for k, v in aws_vpc_endpoint.this : k => v.id
        }
    )
}