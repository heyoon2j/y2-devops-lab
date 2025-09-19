# project_id = default
# zone       = default
# ami_name       = "custom-ubuntu20-{{timestamp}}"

os_name                 = "ubuntu20"
source_image_family     = "ubuntu-2004-lts"
source_image_project_id = "ubuntu-os-cloud"
ssh_username            = "packer"
machine_type            = "e2-medium"
