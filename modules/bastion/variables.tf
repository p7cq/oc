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

variable "oke_api_endpoint_host" {
  type        = string
  description = "OKE API endpoint host"
}

variable "oke_api_endpoint_port" {
  type        = string
  description = "OKE API endpoint port"
}

variable "subnet_ocid" {
  type        = string
  description = "Bastion subnet OCID"
}
