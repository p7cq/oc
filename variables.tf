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
  default = {
    "acme_email" = ""
    "bastion" = {
      "allow_from_cidr_blocks" = []
      "enabled"                = false
      "local_port"             = 6443
      "local_private_key_path" = ""
      "session_ttl"            = 1800
    }
    "compartment_ocid"   = ""
    "kubernetes"         = false
    "load_balancer_host" = ""
    "name"               = ""
    "lan_cidr_block"     = ""
    "vcn_cidr_block"     = ""
    "version" = {
      "cert_manager"  = ""
      "load_balancer" = ""
      "mysql"         = ""
      "nextcloud"     = ""
      "kubernetes"    = ""
      "oracle_linux"  = ""
      "redis"         = ""
    }
  }
}

variable "region" {
  type        = string
  description = "OCI region"
}

variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID"
}
