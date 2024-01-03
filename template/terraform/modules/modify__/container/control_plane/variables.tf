variable "control_plane" {
    description = "Control_plane Information"
    type = object({
        name = string                   # Control Plane's Name
        version = optional(string)                # Control Plane's Version
        role_arn = string               # Control Plane's Role
        
        # VPC Network Config (== Physical)
        vpc_config = object({
            subnet_ids = list(string)
            security_group_ids = list(string)
            endpoint_private_access = optional(bool, true)
            endpoint_public_access  = optional(bool, false)
            public_access_cidrs = optional(list(string))
        })

        # Kubernetes Network Config (== Logical)
        kubernetes_network_config = optional(object({
            ip_family = optional(string, "ipv4")            # "ipv4" or "ipv6"
            service_ipv4_cidr = optional(string, "10.100.0.0/16")       # ex> "10.100.0.0/16"
        }))

        # Encryption for Secrets object
        encryption_config = optional(object({
            key_arn = string
            resources = optional(list(string), ["secrets"]) # ["secrets"]
        }))

        enabled_cluster_log_types = optional(list(string))  # ["api", "audit", "authenticator", "controllManager", "scheduler"]
        tags = optional(map(any))

    })
    # validation {
    #     condition = contains(["disable", "enable"], var.auto_accept_shared_attachments)
    #     error_message = "Only disable or enable"

    #     enabled_cluster_log_types = ["api", "audit", "authenticator", "controllManager", "scheduler"]
    # }
}


# variable "add_on" {
#     description = "Control plain Add-On"
#     type = map(object({
#         cluster_name = string
#         addon_name = string
#         addon_version = optional(string)
#         service_account_role_arn = optional(string)

#         configuration_values = optional(map(any))
        
#         tags = optional(map(any))


#         resolve_conflicts_on_create = optional(string)
#         # NONE : 마이그레이션 진행 시, Self-managed add-on 설정 값을 그대로 가주간다.
#         # OVERWRITE : 마이그레이션 시, AWS EKS 기본 값으로 덮어쓰여 진다. 
#         resolve_conflicts_on_update = optional(string)
#         # NONE : Update 시에, 기존 값을 그대로 가주간다 (단, 업데이트에 실패할 수 있다)
#         # OVERWRITE : Update 시에, AWS EKS 기본 값으로 덮어쓰여 진다.
#         # PESERVE : Update 시에, 기존 값을 보존한다.

#         # 자체 관리할 수 있도록 추가 기능 소프트웨어, 리소스를 남기고 싶은지? (보통은 삭제하고, AddOn도 삭제하는게 맞지 않나?)
#         preserve = optional(bool)
#     }))    
# }