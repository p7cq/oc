output "session_ocid" {
  value = try(oci_bastion_session.this[0].id, "not_found")
}
