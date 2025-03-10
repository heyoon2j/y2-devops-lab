source "amazon-ebs" "ubuntu" {
    region              = var.aws_region
    
    source_ami_filter {
    filters = {
        name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
        virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical 공식 Ubuntu AMI
    }
    instance_type       = var.instance_type
    ssh_username       = "ubuntu"
    ami_name           = "custom-ubuntu-20.04-{{timestamp}}"
}
