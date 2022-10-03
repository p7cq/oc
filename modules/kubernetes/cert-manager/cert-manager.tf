resource "helm_release" "cert_manager" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  chart      = "cert-manager"
  name       = "cert-manager"
  namespace  = var.namespace
  repository = "https://charts.jetstack.io"
  version    = var.oc.version.cert_manager

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "time_sleep" "this" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  create_duration = "30s"

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "cert_issuer" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  chart      = "cert-issuer"
  name       = var.issuer.name
  namespace  = var.namespace
  repository = path.module

  set {
    name  = "fullnameOverride"
    value = var.issuer.name
  }
  set {
    name  = "privateKeySecretRef"
    value = var.issuer.name
  }
  set {
    name  = "ingressClass"
    value = "nginx"
  }
  set {
    name  = "acmeEmail"
    value = var.oc.acme_email
  }
  set {
    name  = "acmeServer"
    value = var.issuer.server
  }

  depends_on = [time_sleep.this]
}
