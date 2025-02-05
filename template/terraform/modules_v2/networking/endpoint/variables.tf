# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VPC Endpoint
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "endpoint" {
    description = "Information of endpoint"
    type = map(object({
        service_name = string
        vpc_endpoint_type = string

        vpc_id       = string
        subnet_ids   = optional(list(string))
        security_group_ids = optional(list(string))
        route_table_ids = optional(list(string))

        tags = optional(map(any))
    }))
}

