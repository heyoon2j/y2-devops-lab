variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "os_name" {
  type = string
}

variable "ami_name" {
  type = string
}

variable "ami_filter_name" {
  type = string
}

variable "ami_filter_owner" {
  type = string
}

variable "ssh_username" {
  type = string
}

source "amazon-ebs" "base" {
  region        = var.aws_region
  profile       = var.aws_profile
  instance_type = "t3.medium"
  ssh_username  = var.ssh_username
  ami_name      = var.ami_name

  source_ami_filter {
    filters = {
      name                = var.ami_filter_name
      virtualization-type = "hvm"
    }
    owners      = [var.ami_filter_owner]
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.base"]

  provisioner "file" {
    source      = "./provisioners/common/install_common_tools.sh"
    destination = "/tmp/install_common_tools.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install_common_tools.sh",
      "/tmp/install_common_tools.sh",
      "./provisioners/aws/install_aws_specific.sh"
    ]
  }

  post-processor "amazon-import" {
    region = var.aws_region
  }
}
