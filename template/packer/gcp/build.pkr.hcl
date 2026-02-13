packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

##############################################
source "googlecompute" "base" {
  project_id                = var.project_id
  zone                      = var.zone
  source_image_family       = var.source_image_family
  source_image_project_id   = var.source_image_project_id
  machine_type              = var.machine_type
  image_name                = var.image_name
}

##############################################
build {
  sources = ["source.googlecompute.base"]

  ##############################################
  # 📂 Copy CSP & Common Scripts
  ##############################################
  provisioner "file" {
    source      = "../provisioners/gcp/init_csp_setting.sh"
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
      #"curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ Packer build complete for ${var.os_name} on ${var.cloud}."}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    ]
  }
}


##############################################
# Variables
##############################################
variable "cloud" {
  type        = string
  description = "클라우드 제공자 이름"
  default     = "gcp"
}

variable "project_id" {
  type        = string
  description = "GCP 프로젝트 ID"
  default     = ""
}

variable "zone" {
  type        = string
  description = "VM을 실행할 GCP zone"
  default     = "asia-northeast3-a"
}

variable "machine_type" {
  type        = string
  default     = "e2-medium"
  description = "임시로 생성되는 GCP VM의 머신 타입"
}

variable "image_name" {
  type        = string
  description = "생성될 이미지 이름"
  default     = "testgcp-os-${var.os_name}-base-${timestamp()}"
}

variable "os_name" {
  type        = string
  description = "OS 이름"
}
variable "source_image_family" {
  type        = string
  description = "베이스 이미지의 family"
}
variable "source_image_project_id" {
  type        = string
  description = "베이스 이미지가 속한 GCP 프로젝트 ID"
}

