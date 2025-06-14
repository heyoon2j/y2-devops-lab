source "amazon-ebs" "pkr" {
  ami_name      = "packer-aws-${var.os_name}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.region
  ...
}
