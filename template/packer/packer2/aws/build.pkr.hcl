##############################################
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

##############################################
source "amazon-ebs" "base" {
  region = var.aws_region
  profile = var.aws_profile

  ssh_username = var.ssh_username
  instance_type = var.instance_type

  ami_name     = var.ami_name
  source_ami_filter {
    filters = {
      name                = var.ami_filter_name
      virtualization-type = "hvm"
    }
    owners      = [var.ami_filter_owner]
    most_recent = true
  }

  subnet_id                   = var.subnet_id
  security_group_id           = var.security_group_id
  associate_public_ip_address = false

  # iam_instance_profile    = "EC2InstanceProfileForSSM"
  metadata_options {
    http_tokens                  = "optional"   # IMDSv1 허용
    http_endpoint                = "enabled"    # IMDS 자체는 활성화
    http_put_response_hop_limit = 1             # 기본값 (옵션)
    instance_metadata_tags       = "enabled"    # 태그 노출 (선택)
  }
}


##############################################
build {
  sources = ["source.amazon-ebs.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "file" {
    source      = "../provisioners/aws/init_csp_setting.sh"
    destination = "/tmp/init_csp_setting.sh"
  }

  provisioner "file" {
    source      = "../provisioners/common/install_common_tools.sh"
    destination = "/tmp/install_common_tools.sh"
  }

  ##############################################
  # 🛠 Run Init CSP Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/init_csp_setting.sh",
      "/tmp/init_csp_setting.sh",
      "rm -f /tmp/init_csp_setting.sh"
    ]
  }

  ##############################################
  # 🛠 Run Common Tool Installer + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install_common_tools.sh",
      "/tmp/install_common_tools.sh",
      "rm -f /tmp/install_common_tools.sh"
    ]
  }

  ##############################################
  # ✅ Notify Completion
  ##############################################
  
post-processor "shell-local" {
  inline = [
    "echo '✅ Build complete for ${var.os_name} on ${var.cloud}'",
    "curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ Packer build complete for ${var.os_name} on ${var.cloud}."}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
  ]
}
}



##############################################
# Variables
##############################################
variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}
variable "aws_profile" {
  type    = string
  default = ""
}
variable "cloud" {
  type    = string
  default = "aws"
}
variable "ami_name" {
  type    = string
  default = "testaws-os-${var.os_name}-base-${timestamp()}"
}
variable "instance_type" {
  type    = string
  default = "t3.medium"
}
variable "subnet_id" {
  type    = string
  default = ""
}
variable "security_group_id" {
  type    = string
  default = ""
}

variable "os_name" {
  type    = string
}
variable "ami_filter_name" {
  teyp    = string
}
variable "ami_filter_owner" {
  type    = string
}
variable "ssh_username" {
  type    = string
}
