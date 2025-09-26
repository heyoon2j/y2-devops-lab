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
    source      = "../provisioners/common/init/"
    destination = "/tmp/init_script"
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
  # 🛠 Run Init Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/init_script/*",
      "/tmp/init_csp_setting.sh",
      


      "rm -rf /tmp/init_script"
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