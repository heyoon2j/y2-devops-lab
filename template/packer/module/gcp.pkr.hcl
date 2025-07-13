variable "gcp_project_id" {
  type = string
}

variable "gcp_zone" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "os_name" {
  type = string
}

variable "ami_name" {
  type = string
}

variable "source_image_family" {
  type = string
}

variable "source_image_project_id" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "machine_type" {
  type = string
  default = "e2-medium"
}

source "googlecompute" "base" {
  project_id              = var.gcp_project_id
  zone                    = var.gcp_zone
  source_image_family     = var.source_image_family
  source_image_project_id = var.source_image_project_id
  machine_type            = var.machine_type
  ssh_username            = var.ssh_username
  image_name              = var.ami_name
}

build {
  sources = ["source.googlecompute.base"]

  provisioner "file" {
    source      = "./provisioners/common/install_common_tools.sh"
    destination = "/tmp/install_common_tools.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install_common_tools.sh",
      "/tmp/install_common_tools.sh",
      "./provisioners/gcp/install_gcp_specific.sh"
    ]
  }
}
