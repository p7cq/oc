resource "helm_release" "this" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  chart      = "ingress-nginx"
  name       = "ingress-nginx"
  namespace  = var.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = var.oc.version.load_balancer

  dynamic "set" {
    for_each = local.controller_set
    content {
      name  = set.value.name
      value = set.value.value
      type  = lookup(set.value, "type", null)
    }
  }
}
