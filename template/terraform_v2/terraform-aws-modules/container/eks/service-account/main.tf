resource "kubernetes_service_account" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = var.role_arn
    }
  }
}