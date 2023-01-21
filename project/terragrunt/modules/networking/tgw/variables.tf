variable "amazon_side_asn" {

} = 64512
## 연결된 교차 계정 연결을 자동으로 수락할지 여부
variable "auto_accept_shared_attachments {

}  = "disable"

# TGW에 Default Routing Table 할당
variable "default_route_table_association {

}  = "disable"
variable "default_route_table_propagation {

}  = "disable"

# DNS Support
variable "dns_support {

}  = "enable"
# VPN ECMP Routing
variable "vpn_ecmp_support {

}  = "enable"
# Multicast Support
variable "multicast_support {
    
}  = "disable"