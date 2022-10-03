data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "oke.sh"
    content_type = "text/x-shellscript"
    content      = local.template
  }
}

data "oci_containerengine_node_pool_option" "this" {
  compartment_id      = var.oc.compartment_ocid
  node_pool_option_id = "all"
}

data "oci_kms_vaults" "this" {
  compartment_id = var.oc.compartment_ocid
  filter {
    name   = "display_name"
    values = [var.oc.name]
  }
}

data "oci_vault_secrets" "this" {
  compartment_id = var.oc.compartment_ocid
  name           = local.ssh_public_key_secret_name
  vault_id       = data.oci_kms_vaults.this.vaults[0].id

  filter {
    name   = "state"
    values = ["ACTIVE"]
  }
}

data "oci_secrets_secretbundle" "this" {
  secret_id = data.oci_vault_secrets.this.secrets.0.id
}
