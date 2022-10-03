data "oci_kms_vaults" "this" {
  count = var.oc.bastion.enabled ? 1 : 0

  compartment_id = var.oc.compartment_ocid
  filter {
    name   = "display_name"
    values = [var.oc.name]
  }
}

data "oci_vault_secrets" "this" {
  count = var.oc.bastion.enabled ? 1 : 0

  compartment_id = var.oc.compartment_ocid
  name           = "bastion-ssh-public"
  vault_id       = data.oci_kms_vaults.this[0].vaults[0].id

  filter {
    name   = "state"
    values = ["ACTIVE"]
  }
}

data "oci_secrets_secretbundle" "this" {
  count = var.oc.bastion.enabled ? 1 : 0

  secret_id = data.oci_vault_secrets.this[0].secrets.0.id
}
