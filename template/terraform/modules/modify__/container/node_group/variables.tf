variable "compute_machines" {
    description = "Compute_Machines Information"
    type = object({
        cluster_name    = string

        # Node Group Configuration
        node_group_name = string
        node_role_arn   = string
        labels          = optional(map(any)) 
        taint           = optional(map(object({
            key = string
            value = string
            effect = string                 # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
        })))

        # Network
        subnet_ids      = list(string)
       
        # EC2 Resource Spec
        launch_template = object({
            id = optional(string)
            name = optional(string)
            version = number
        })
            # ami_type - (Optional) Type of Amazon Machine Image (AMI) associated with the EKS Node Group. See the AWS documentation for valid values. Terraform will only perform drift detection if a configuration value is provided.
            # release_version – (Optional) AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version.
            # instance_types - (Optional) List of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided.
            # capacity_type - (Optional) Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided.
            # disk_size - (Optional) Disk size in GiB for worker nodes. Defaults to 50 for Windows, 20 all other node groups. Terraform will only perform drift detection if a configuration value is provided.
        scaling_config  = object({
            desired_size = number
            max_size     = number
            min_size     = number
        })

        remote_access = optional(map(object({
            ec2_ssh_key = optional(string)
            source_security_group_ids = optional(list(string))
        })))

        # 업데이트 사용 불가 가능 갯수
        update_config   = object({
            max_unavailable = optional(number)
            max_unavailable_percentage = optional(number)
        })

        tags = optional(map(any))
    })

}