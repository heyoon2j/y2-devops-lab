variable "efs" {
    description = "EFS Information"
    type = list(object({
        creation_token = string

        subnet_id = string
        # One Zone 인 경우만 해당!!
        availability_zone_name = string

        # Encyption
        encrypted = bool
        kms_key_id = string

        # Class Type
        performance_mode = string
        throughput_mode = string
        provisioned_throughput_in_mibps = number

        # Lifecycle
        lifecycle_transition_to_ia = string
        lifecycle_transition_to_primary_storage_class = string

        # Backup
        use_autoBackup = string

        tags = map(string)
    }))
}

variable "efs_policy" {
    description = "EFS policy Information"
    type = list(object({
        name = string
        policy = string 
    }))
}


variable "efs_mount_target" {
    description = "EFS Interface Information"
    type = list(object({
        efs_name = string
        subnet_name = string
        ip_address = string
        security_groups = list(string)
    }))
}