variable "ad" {
  type = object({
    ad1 = string
  })
  description = "Availability domains; affects node pool size"
}

variable "api_subnet_ocid" {
  type        = string
  description = "Kubernetes API private subnet OCID"
}

variable "lb_subnet_ocid" {
  type        = string
  description = "Kubernetes public subnet OCID"
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

variable "vcn_ocid" {
  type        = string
  description = "VCN OCID"
}

variable "worker_subnet_ocid" {
  type        = string
  description = "Kubernetes worker node private subnet OCID"
}
