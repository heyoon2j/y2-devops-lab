##############################################
build {
  sources = ["source.amazon-ebs.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/packer/files",
      "mkdir -p /tmp/packer/config",
      "mkdir -p /tmp/packer/script",
    ]
  }

  provisioner "file" {
    source      = "./provisioners/files/"
    destination = "/tmp/packer/files"
  }

  provisioner "file" {
    source      = "./provisioners/config/"
    destination = "tmp/packer/config"
  }

  provisioner "file" {
    source      = "./provisioners/script/"
    destination = "/tmp/packer/script"
  }

  ##############################################
  # 🛠 Run Init Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/packer/script/common/init/*",
      "chmod +x /tmp/packer/script/common/check_os.sh",
      "chmod +x /tmp/packer/script/common/check_arch.sh",
      "OS_ID=$(/tmp/packer/script/common/check_os.sh)",
      "ARCH=$(/tmp/packer/script/common/check_arch.sh)",
      "/tmp/packer/script/common/init/00_init_cloud_cfg.sh",
      "/tmp/packer/script/common/init/01_init_ssh.sh",
      "/tmp/packer/script/common/init/02_init_selinux.sh $OS_ID",
      "/tmp/packer/script/common/init/03_init_dns_resolve.sh $OS_ID ${var.cloud}",
      "/tmp/packer/script/common/init/04_init_repository.sh $OS_ID $ARCH",
      "/tmp/packer/script/common/init/05_install_package.sh $OS_ID",
      "/tmp/packer/script/common/init/06_init_ntp.sh $OS_ID",
      "/tmp/packer/script/common/init/07_set_sudoeors.sh",
      "/tmp/packer/script/common/init/08_set_git_python.sh",
      "/tmp/packer/script/common/init/09_sysctl.sh",
      "/tmp/packer/script/common/init/10_rsyslog.sh",
      "/tmp/packer/script/common/init/99_last.sh",
    ]
  }


  ##############################################
  # 🛠 Run Init OS (each) + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/packer/script/os/*",
      "/tmp/packer/script/os/${var.os_name}/init_os_setting.sh",
    ]
  }


  ##############################################
  # 🛠 Run Init CSP Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/packer/script/cloud/*",
      "/tmp/packer/script/cloud/${var.cloud}/init_csp_setting.sh",
    ]
  }

  ##############################################
  # 🛠 Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "rm -rf /tmp/packer"
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