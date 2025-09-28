##############################################
# Variables
##############################################

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
variable "security_group_id" {
  type    = string
  default = ""
}
##############################
##############################
# OS Variables
variable "os_name" {
  type    = string
}
variable "ami_filter_name" {
  type    = string
}
variable "ami_filter_owner" {
  type    = string
}
variable "ssh_username" {
  type    = string
}
##############################



##############################################
# Source
##############################################
source "amazon-ebs" "base" {
  region = var.aws_region
  profile = var.aws_profile

  ssh_username = var.ssh_username
  instance_type = var.instance_type

  ami_name     = "testaws-os-${var.os_name}-base-${formatdate("YYMMDD", timestamp())}"
  source_ami_filter {
    filters = {
      name                = var.ami_filter_name
      virtualization-type = "hvm"
    }
    owners      = [var.ami_filter_owner]
    most_recent = true
  }

  subnet_id                   = var.subnet_id
  security_group_id           = var.security_group_id
  associate_public_ip_address = false

  # iam_instance_profile    = "EC2InstanceProfileForSSM"
  metadata_options {
    http_tokens                  = "optional"   # IMDSv1 허용
    http_endpoint                = "enabled"    # IMDS 자체는 활성화
    http_put_response_hop_limit = 1             # 기본값 (옵션)
    instance_metadata_tags       = "enabled"    # 태그 노출 (선택)
  }
}