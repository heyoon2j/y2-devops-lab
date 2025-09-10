
source "amazon-ebs" "base" {
  region = var.aws_region
  profile = var.aws_profile
  ssh_username = var.ssh_username
  ami_name     = var.ami_name
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
    source      = "./provisioners/aws/init_csp_setting.sh"
    destination = "/tmp/init_csp_setting.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/init_csp_setting.sh",
      "/tmp/init_csp_setting.sh"
    ]
  }

  provisioner "file" {
    source      = "./provisioners/common/install_common_tools.sh"
    destination = "/tmp/install_common_tools.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install_common_tools.sh",
      "/tmp/install_common_tools.sh"
    ]
  }

  
post-processor "shell-local" {
  inline = [
    "echo '✅ Build complete for ${var.os_name} on ${var.cloud}'",
    "curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ Packer build complete for ${var.os_name} on ${var.cloud}."}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
  ]
}
}