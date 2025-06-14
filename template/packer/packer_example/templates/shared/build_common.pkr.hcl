build {
  sources = ["source.pkr.hcl"]
  provisioner "shell" {
    script = "modules/${var.os_name}/install.sh"
  }
}
