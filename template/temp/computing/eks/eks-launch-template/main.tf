resource "aws_launch_template" "this" {
  name_prefix = var.name_prefix

  image_id = var.image_id != null ? var.image_id : null

  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.volume_size
      volume_type = var.volume_type
    }
  }

  metadata_options {
    http_tokens = "required"
  }

  user_data = var.user_data

  tag_specifications {
    resource_type = "instance"

    tags = var.tags
  }
}
