# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VPN
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

output "cgw_id" {
    description = "Custom Gateway ID"
    value = aws_customer_gateway.main.id
}