resource "aws_kms_key" "this" {
  description         = var.description
  enable_key_rotation = true
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.id
}