resource "aws_network_acl_association" "this" {
  subnet_id      = var.subnet_id
  network_acl_id = var.network_acl_id
}