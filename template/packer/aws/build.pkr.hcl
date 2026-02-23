##############################################
build {
  sources = ["source.amazon-ebs.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "shell" {
    inline = [
      "mkdir -p /opt/packer/files",
      "mkdir -p /opt/packer/config",
      "mkdir -p /opt/packer/script"
    ]
  }

  provisioner "file" {
    source      = "./provisioners/files/"
    destination = "/opt/packer/files"
  }

  provisioner "file" {
    source      = "./provisioners/config/"
    destination = "tmp/packer/config"
  }

  provisioner "file" {
    source      = "./provisioners/script/"
    destination = "/opt/packer/script"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/packer/"
    ]
  }

  provisioner "file" {
    source      = "./provisioners/"
    destination = "/opt/packer/"
  }

  ##############################################
  # 🛠 Run Init Script + Cleanup
  ##############################################
  provisioner "shell" {
    timeout = "5m"

    inline = [
      "sudo chmod +x /opt/packer/script/utils/*",
      "sudo chmod +x /opt/packer/script/common/init/*",
      "sudo /opt/packer/script/common/init/00_init_cloud_cfg.sh",
      "sudo /opt/packer/script/common/init/01_init_ssh.sh",
      "sudo /opt/packer/script/common/init/02_init_selinux.sh ${var.os_name}",
      "sudo /opt/packer/script/common/init/03_init_dns_resolve.sh ${var.os_name} ${var.cloud}",
      "sudo /opt/packer/script/common/init/04_init_repository.sh ${var.os_name} ${var.arch_type}",
      "sudo /opt/packer/script/common/init/05_install_package.sh ${var.os_name}",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'System will now reboot to apply all updates..'",
      "sudo reboot"
    ]
    expect_disconnect = true
    timeout = "5m"
  }

  provisioner "shell" {
    pause_before  = "5m"
    timeout       = "5m"
    inline = [
      "sudo /opt/packer/script/common/init/06_init_ntp.sh ${var.os_name}",
      "sudo /opt/packer/script/common/init/07_set_sudoeors.sh",
      "sudo /opt/packer/script/common/init/08_set_git_python.sh",
      "sudo /opt/packer/script/common/init/09_sysctl.sh",
      "sudo /opt/packer/script/common/init/10_rsyslog.sh",
      "sudo /opt/packer/script/common/init/99_last.sh",
    ]
  }

  ##############################################
  # Run Security Script
  ##############################################
  provisioner "shell" {
    inline = [
      "sudo chmod +x /opt/packer/script/security/srv/*",
      "sudo /opt/packer/script/security/srv/patch_srv.sh"
    ]
  }

  ##############################################
  # 🛠 Run Init OS (each) + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "sudo chmod +x /opt/packer/script/os/${var.os_name}/*",
      "sudo /opt/packer/script/os/${var.os_name}/init_os_setting.sh",
    ]
  }


  ##############################################
  # 🛠 Run Init CSP Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "sudo chmod +x /opt/packer/script/cloud/${var.cloud}/*",
      "sudo /opt/packer/script/cloud/${var.cloud}/init_csp_setting.sh",
    ]
  }

  ##############################################
  # ✅ Validation & Logging
  ##############################################
  provisioner "shell" {
    inline = [
      "echo '[INFO] Running validation scripts...'",
      "sudo chmod +x /opt/packer/script/validation/*",
      "sudo /opt/packer/script/validate/a.sh"
    ]
  }

  provisioner "file" {
    source      = "/opt/packer/validation.log"
    destination = "./validation.log"
    direction   = "download"
  }

  ##############################################
  # 🛠 Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "rm -rf /opt/packer"
    ]
  }

  ##############################################
  # ✅ Notify Completion
  ##############################################
  post-processor "shell-local" {
    inline = [
      "echo '✅ Build complete for ${var.os_name} on ${var.cloud}'",
      # "curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ Packer build complete for ${var.os_name} on ${var.cloud}."}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    ]
  }
}