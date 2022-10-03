variable "issuer" {
  type = object({
    name   = string
    server = string
  })
  description = "Default certificate issuer"
  default = {
    name   = "letsencrypt"
    server = "https://acme-v02.api.letsencrypt.org/directory"
  }
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
