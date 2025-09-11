
source "googlecompute" "base" {
  project_id = var.gcp_project_id
  zone = var.gcp_zone
  source_image_family = var.source_image_family
  source_image_project_id = var.source_image_project_id
  machine_type = var.machine_type
  ssh_username = var.ssh_username
  ami_name     = var.ami_name
  
}
build {
  sources = ["source.googlecompute.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "file" {
    source      = "./provisioners/gcp/init_csp_setting.sh"
    destination = "/tmp/init_csp_setting.sh"
  }

  provisioner "file" {
    source      = "./provisioners/common/install_common_tools.sh"
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