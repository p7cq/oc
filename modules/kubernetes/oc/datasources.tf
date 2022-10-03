data "oci_kms_vaults" "this" {
  compartment_id = var.oc.compartment_ocid
  filter {
    name   = "display_name"
    values = [var.oc.name]
  }
}

data "oci_vault_secrets" "this" {
  compartment_id = var.oc.compartment_ocid
  name           = var.oc.name
  vault_id       = data.oci_kms_vaults.this.vaults[0].id

  filter {
    name   = "state"
    values = ["ACTIVE"]
  }
}

data "oci_secrets_secretbundle" "this" {
  secret_id = data.oci_vault_secrets.this.secrets.0.id
}
