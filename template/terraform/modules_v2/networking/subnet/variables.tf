

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Subnet
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# variable "sbn_common_config" {
#     description = "Subnet default config"
#     type = object({
#         naming_rule = string
#         assign_ipv6_address_on_creation = optional(bool, false)
#         map_public_ip_on_launch = optional(bool, false)
#         #private_dns_hostname_type_on_launch =  string
#         tags = optional(map(any),null)
#     })
# }

variable "sbn" {
    description = "Subnet Dictionary Value"
    type = map(object({
        name = string
        cidr_block = string
        ipv6_cidr_block = optional(string, null)
        availability_zone = string
        route_table = optional(string, null)
        assign_ipv6_address_on_creation = optional(bool, false)
        map_public_ip_on_launch = optional(bool, true)
        tags = optional(map(any), null)
    }))
}
/*
variable "sbn_pri" {
    description = "Private Subnet Dictionary Value"
    type = map(object({
        name = string
        cidr_block = string
        ipv6_cidr_block = optional(string, null)
        availability_zone = string
        route_table = optional(string, null)
        assign_ipv6_address_on_creation = optional(bool, false)
        map_public_ip_on_launch = optional(bool, false)
        tags = optional(map(any), null)
    }))
}
*/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Routing Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "rt" {
    description = "Routing Table"
    type = map(object({
        name = string
        tags = optional(map(any),null)
    }))
}

/*
variable "rt_pri" {
    description = "Private Routing Table"
    type = map(object({
        name = string
        tags = optional(map(any),null)
    }))
}
*/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Routing Table
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "igw" {
    description = "Internet Gateway Name"
    default = null
    type = string
}

variable "igw_tags" {
    description = "Internet Gateway Tags"
    default = null
    type = map(any)
}