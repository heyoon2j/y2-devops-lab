# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VPN Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "name" {
    description = "VPN Name"
    type = string
}

variable "vpc_id" {
    description = "VPC ID"
    type = string
}

variable "amazon_side_asn" {
    description = "Amazon side ASN - 64,512 ~ 65,534 or 4,200,000,000 ~ 4,294,967,294"
    type = number
    default = 64512
}

variable "tags" {
    description = "Tags"
    type = map(any)
    default = null
}
