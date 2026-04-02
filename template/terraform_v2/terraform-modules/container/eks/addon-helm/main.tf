resource "helm_release" "this" {
  name       = var.name
  repository = var.repository
  chart      = var.chart
  namespace  = var.namespace

  ##########################################
  # values.yaml 대응
  ##########################################
  values = var.values != null ? [yamlencode(var.values)] : null

  ##########################################
  # set values
  ##########################################
  dynamic "set" {
    for_each = var.set_values != null ? var.set_values : {}
    content {
      name  = set.key
      value = set.value
    }
  }
}