module "vpc" {
  source = "../../../terraform-modules/vpc"

  cidr_block = var.vpc_cidr
  name       = var.vpc_name
  tags       = var.tags
  
  instance_tenancy                      = "default"
  enable_dns_support                    = true
  enable_dns_hostnames                  = true
  enable_network_address_usage_metrics  = false
}

module "subnet" {
  for_each = var.features.subnet ? var.subnets : {}

  source = "../../../modules/network/subnet"

  vpc_id = module.vpc.vpc_id
  name   = each.key
  cidr_block   = each.value.cidr_block
  availability_zone     = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = var.tags
}

module "nacl" {
  count = var.features.nacl ? 1 : 0

  source = "../../../modules/network/network-acl/nacl"

  vpc_id  = module.vpc.vpc_id
  name    = "${var.vpc_name}-nacl"

  tags    = var.tags
}

module "nacl_ingress_rule" {
  for_each = var.features.nacl ? var.nacl_ingress_rule : {}

  source = "../../../modules/network/netowkr-acl/nacl-rule"

  network_acl_id = module.nacl.nacl_id
  rule_number    = each.value.rule_number
  egress         = false
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block

  from_port = each.value.from_port
  to_port   = each.value.to_port
}

module "nacl_egress_rule" {
  count = var.features.nacl ? 1 : 0

  source = "../../../modules/network/netowkr-acl/nacl-rule"

  network_acl_id = module.nacl.nacl_id
  rule_number    = each.value.rule_number
  egress         = true
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block

  from_port = each.value.from_port
  to_port   = each.value.to_port
}

