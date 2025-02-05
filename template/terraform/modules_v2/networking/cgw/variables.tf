# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Customer Gateway
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "name" {
    description = "VPN Name"
    type = string
}

variable "device_name" {
    description = "Device Name"
    type = string
}

variable "type" {
    description = "VPN Protocol Type - Only type : ipsec.1"
    type = string
    default = "ipsec.1"
    validation {
        condition = var.type == "ipsec.1" ? true : false #contains(["ipsec.1"], var.type)
        error_message = "[error] Only type : ipsec.1"
    }
}

variable "bgp_asn" {
    description = "Custom Network's ASN for BGP"
    type = number
    default = 65000
}

variable "ip_address" {
    description = "Custom Gateway Public IP"
    type = string
}

variable "certificate_arn" {
    description = "Certificate ARN (AWS ACM)"
    type = string
    default = null
}

variable "tags" {
    description = "Tags"
    type = map(any)
    default = null
}
