##############################################
# Variables
##############################################

##############################
# Entrypoint Variables
variable "ssh_username" {
  type    = string
}
variable "ssh_password" {
  type    = string
}

##############################
# Common Variables
variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}
variable "aws_profile" {
  type    = string
  default = ""
}
variable "cloud" {
  type    = string
  default = "aws"
}
variable "instance_type" {
  type    = string
  default = "t3.medium"
}
variable "subnet_id" {
  type    = string
  default = ""
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
#variable "security_group_id" {
#  type    = string
#  default = ""
#}

##############################
# OS Variables
variable "os_name" {
  type    = string
}
variable "arch_type" {
  type    = string
}
variable "ami_filter_name" {
  type    = string
}
variable "ami_filter_owner" {
  type    = string
}


##############################################
# Source
##############################################
source "amazon-ebs" "base" {
  region = var.aws_region
  profile = var.aws_profile
  ssh_pty = true

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password

  instance_type = var.instance_type

  ami_name     = "testaws-${var.os_name}_${var.arch_type}-base-${formatdate("YYMMDD", timestamp())}"
  source_ami_filter {
    filters = {
      name                = var.ami_filter_name
      virtualization-type = "hvm"
    }
    owners      = [var.ami_filter_owner]
    most_recent = true
  }

  # userdata - 임시 계정 생성
  user_data = base64encode(<<-EOT
#!/bin/bash
set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
CLOUD_CONFIG="/etc/cloud/cloud.cfg"

echo "========== SSH Setting Start =========="

########################################################
## cloud-init 설정 - ssh_pwauth 값 변경
echo "[INFO] Updating Cloud config file: $CLOUD_CONFIG"

if grep -q "^ssh_pwauth:" "$CLOUD_CONFIG"; then
  sudo sed -i 's/ssh_pwauth:\s*0\s*/ssh_pwauth: 1/' "$CLOUD_CONFIG"
  sudo sed -i 's/ssh_pwauth:\s*false\s*/ssh_pwauth: true/' "$CLOUD_CONFIG"
#else
#    echo -e "\nssh_pwauth:   true" | sudo tee -a "$CLOUD_CONFIG"
fi
echo "[OK] $CLOUD_CONFIG 내 ssh_pwauth 설정이 완료되었습니다."


## cloud-init sshd 파일 변경
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
  sudo mv /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak
  echo "[OK] Disable cloud-init - SSHD config"
fi

if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
  sudo mv /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/ssh/sshd_config.d/50-cloud-init.conf.bak
  echo "[OK] Disable cloud-init - SSHD config"
fi

########################################################
# PasswordAuthentication 설정 변경
echo "[INFO] Updating SSHD config: $SSHD_CONFIG"
if grep -q "^#*PasswordAuthentication" "$SSHD_CONFIG"; then
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication yes" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi
echo "[OK] PasswordAuthentication Setting"

########################################################
# 기본 계정 생성
useradd -m -s /bin/bash -G wheel packer
echo 'packer ALL=(ALL) NOPASSWD:ALL' | tee /etc/sudoers.d/packer
chmod 0440 /etc/sudoers.d/packer
mkdir -p /home/packer/.ssh
chmod 700 /home/packer/.ssh
EOT
  )

  subnet_id                   = var.subnet_id
  # security_group_id           = var.security_group_id
  security_group_ids          = var.security_group_ids
  associate_public_ip_address = false

  # iam_instance_profile    = "EC2InstanceProfileForSSM"
  metadata_options {
    http_tokens                  = "optional"   # IMDSv1 허용
    http_endpoint                = "enabled"    # IMDS 자체는 활성화
    http_put_response_hop_limit = 1             # 기본값 (옵션)
    instance_metadata_tags       = "enabled"    # 태그 노출 (선택)
  }
}