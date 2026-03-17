data "aws_eks_addon_version" "this" {
  addon_name         = var.addon_name
  kubernetes_version = var.kubernetes_version
}

resource "aws_eks_addon" "this" {
  cluster_name  = var.cluster_name
  addon_name    = var.addon_name
  addon_version = data.aws_eks_addon_version.this.version

  resolve_conflicts_on_update = "OVERWRITE"
}
