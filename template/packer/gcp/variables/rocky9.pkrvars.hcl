# project_id = default
# zone       = default
# ami_name       = "custom-ubuntu20-{{timestamp}}"

os_name                 = "rocky8"
source_image_family     = "rocky-linux-8"
source_image_project_id = "rocky-linux-cloud"
ssh_username            = "packer"
machine_type            = "e2-medium"