variable "ingress_secret_name" {
  type        = string
  description = "Kubernetes secret name used by Nextcloud ingress"
}

variable "issuer" {
  type = object({
    name   = string
    server = string
  })
  description = "Current certificate issuer"
}

variable "load_balancer_cidr" {
  type        = string
  description = "Load balancer subnet CIDR block"
}

variable "load_balancer_ip" {
  type        = string
  description = "Load balancer reserved IP"
}

variable "max_upload_size" {
  type        = string
  description = "Maximum upload size"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace"
}

variable "oc" {
  type = object({
    acme_email = string
    bastion = object({
      allow_from_cidr_blocks = list(string)
      enabled                = bool
      local_port             = string
      local_private_key_path = string
      session_ttl            = string
    })
    compartment_ocid   = string
    kubernetes         = bool
    load_balancer_host = string
    name               = string
    lan_cidr_block     = string
    vcn_cidr_block     = string
    version = object({
      cert_manager  = string
      load_balancer = string
      mysql         = string
      nextcloud     = string
      kubernetes    = string
      oracle_linux  = string
      redis         = string
    })
  })
  description = "Main configuration"
}

variable "oc_output_directory" {
  type        = string
  description = "Output directory for generated files"
}

variable "reset" {
  type        = bool
  description = "Reset resource: true removes, false creates"
}

variable "worker_hostname_map" {
  type        = map(string)
  description = "Worker hostnames in Kubernetes"
}
