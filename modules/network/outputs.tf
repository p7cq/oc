output "bastion_subnet_ocid" {
  value = try(oci_core_subnet.bastion_public[0].id, "not_found")
}

output "vcn_ocid" {
  value = oci_core_vcn.this.id
}

output "oke_lb_reserved_ip" {
  value = try(oci_core_public_ip.this.ip_address, "not_found")
}

output "oke_api_subnet_ocid" {
  value = try(oci_core_subnet.oke_api_private.id, "not_found")
}

output "oke_lb_subnet_cidr" {
  value = try(oci_core_subnet.oke_lb_public.cidr_block, "not_found")
}

output "oke_lb_subnet_ocid" {
  value = try(oci_core_subnet.oke_lb_public.id, "not_found")
}

output "oke_worker_subnet_ocid" {
  value = try(oci_core_subnet.oke_worker_private.id, "not_found")
}
