output "ingress_secret_name" {
  value = join("-", [var.issuer.name, "tls", "secret"])
}

output "max_upload_size" {
  value = local.max_upload_size
}

output "namespace" {
  value = local.namespace
}

output "issuer" {
  value = var.issuer
}

output "reset" {
  value = local.reset
}

output "worker_hostname_map" {
  value = local.worker_hostname_map
}
