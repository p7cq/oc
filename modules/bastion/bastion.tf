resource "oci_bastion_bastion" "this" {
  count = var.oc.bastion.enabled ? 1 : 0

  bastion_type                 = "STANDARD"
  client_cidr_block_allow_list = var.oc.bastion.allow_from_cidr_blocks
  compartment_id               = var.oc.compartment_ocid
  max_session_ttl_in_seconds   = 10800
  name                         = join("-", [var.oc.name, "bastion"])
  target_subnet_id             = var.subnet_ocid
}

resource "oci_bastion_session" "this" {
  count = var.oc.bastion.enabled ? 1 : 0

  bastion_id   = oci_bastion_bastion.this[0].id
  display_name = "oc-bastion-session"

  key_details {
    public_key_content = base64decode(data.oci_secrets_secretbundle.this[0].secret_bundle_content.0.content)
  }

  session_ttl_in_seconds = var.oc.bastion.session_ttl

  target_resource_details {
    session_type                       = "PORT_FORWARDING"
    target_resource_id                 = ""
    target_resource_private_ip_address = var.oke_api_endpoint_host
    target_resource_port               = var.oke_api_endpoint_port
  }
}
