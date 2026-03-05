##############################################
build {
  sources = ["source.amazon-ebs.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /tmp/packer",
      "sudo chown -R packer:packer /tmp/packer",
      "sudo mkdir -p /opt/packer"
    ]
  }

  provisioner "file" {
    source      = "./provisioners/"
    destination = "/tmp/packer"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/packer/* /opt/packer/"
    ]
  }

  ##############################################
  # 🛠 Run Init Script + Cleanup
  ##############################################
  provisioner "shell" {
    timeout = "30m"

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
    timeout       = "30m"
    inline = [
      "sudo /opt/packer/script/common/init/06_init_ntp.sh ${var.os_name}",
      "sudo /opt/packer/script/common/init/07_set_auth.sh",
      "sudo /opt/packer/script/common/init/08_set_bootstrap.sh",
      "sudo cp -r /opt/packer/files/bootstrap/* /opt/",
      "sudo /opt/packer/script/common/init/09_sysctl.sh",
      "sudo /opt/packer/script/common/init/10_rsyslog.sh ${var.os_name} ${var.arch_type}",
      "sudo /opt/packer/script/common/init/11_log.sh",
      "sudo /opt/packer/script/common/init/12_install_aws-cli.sh ${var.arch_type}"
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
      "echo 'System will now reboot to apply all setting..'",
      "sudo reboot"
    ]
    expect_disconnect = true
    timeout = "5m"
  }

  provisioner "shell" {
    pause_before  = "5m"
    inline = [
      "echo '[INFO] Running validation scripts...'",
      "sudo chmod +x /opt/packer/script/validation/*",
      "sudo /opt/packer/script/validation/validate_init.sh",
      "sudo /opt/packer/script/validation/validate_${var.os_name}.sh",
      "sudo /opt/packer/script/validation/validate_${var.cloud}.sh"
    ]
  }

  ##############################################
  # 🛠 Cleanup
  ##############################################
  provisioner "shell" {
    inline = [
      "sudo rm -rf /opt/packer"
    ]
  }

  ##############################################
  # ✅ Notify Completion
  ##############################################
  post-processor "shell-local" {
    inline = [
      "echo '✅ Build complete for ${var.os_name} on ${var.cloud}'",
      "echo 'Log file: ${var.log_file_name}'",
      "echo 'Uploading log to S3: s3://${var.s3_bucket}/${var.s3_path}/${var.log_file_name}'",
      # "aws s3 cp '${var.log_file_name}' 's3://${var.s3_bucket}/${var.s3_path}/${var.log_file_name}' && echo 'Log uploaded successfully' || echo 'S3 upload failed or AWS credentials not configured'"
      # "curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ Packer build complete for ${var.os_name} on ${var.cloud}."}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    ]
  }
}