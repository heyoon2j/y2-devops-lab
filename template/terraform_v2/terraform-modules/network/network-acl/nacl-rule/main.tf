resource "aws_network_acl_rule" "this" {
  network_acl_id = var.nacl_id
  rule_number    = var.rule_number
  egress         = var.egress
  protocol       = var.protocol
  rule_action    = var.rule_action
  cidr_block     = var.cidr_block

  from_port = var.from_port
  to_port   = var.to_port
}