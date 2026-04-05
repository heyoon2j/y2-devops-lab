resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.name

  node_role_arn = var.node_role_arn
  subnet_ids    = var.subnet_ids

  ##################################
  # scaling
  ##################################
  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  ##################################
  # compute
  ##################################
  instance_types = var.instance_types
  capacity_type  = var.capacity_type

  ##################################
  # labels
  ##################################
  labels = var.labels

  ##################################
  # taints
  ##################################
  dynamic "taint" {
    for_each = var.taints != null ? var.taints : []
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
}