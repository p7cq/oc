output "ocid" {
  value = try(oci_containerengine_cluster.this.id, "not_found")
}

output "private_endpoint_host" {
  value = try(split(":", try(oci_containerengine_cluster.this.endpoints[0].private_endpoint, "not_found"))[0], "not_found")
}

output "private_endpoint_port" {
  value = try(split(":", try(oci_containerengine_cluster.this.endpoints[0].private_endpoint, "not_found"))[1], "not_found")
}
