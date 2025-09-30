##############################################
build {
  sources = ["source.amazon-ebs.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/config",
      "mkdir -p /tmp/common",
      "mkdir -p /tmp/${var.cloud}"
    ]
  }

  provisioner "file" {
    source      = "../provisioners/config/"
    destination = "/tmp/config"
  }

  provisioner "file" {
    source      = "../provisioners/common/"
    destination = "/tmp/common"
  }

  provisioner "file" {
    source      = "../provisioners/${var.cloud}/"
    destination = "/tmp/cloud"
  }

  ##############################################
  # 🛠 Run Init Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/common/check_os.sh",
      "chmod +x /tmp/common/init/*",
      # "OS_ID=$(/tmp/common/check_os.sh)",
      "/tmp/common/init/00_init_cloud_cfg.sh",
      "/tmp/common/init/01_init_ssh.sh",
      "/tmp/common/init/02_init_selinux.sh $OS_ID",
      "/tmp/common/init/03_init_dns_resolve.sh $OS_ID",
      "/tmp/common/init/04_init_repository.sh $OS_ID $ARCH",
      "/tmp/common/init/05_install_package.sh $OS_ID",
      "/tmp/common/init/06_init_ntp.sh $OS_ID",
      "/tmp/common/init/07_set_sudoeors.sh",
      "/tmp/common/init/08_set_git.sh",
      "/tmp/common/init/09_sysctl.sh",
      "/tmp/common/init/10_rsyslog.sh",
      "/tmp/common/init/99_last.sh",
      "rm -rf /tmp/common/init"
    ]
  }

  ##############################################
  # 🛠 Run Init CSP Script + Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cloud/*",
      "/tmp/cloud/init_csp_setting.sh",
      "rm -f /tmp/cloud"
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