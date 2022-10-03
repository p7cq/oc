data "oci_core_instances" "this" {
  compartment_id = var.oc.compartment_ocid

  filter {
    name   = "state"
    values = ["RUNNING"]
  }
  filter {
    name   = "display_name"
    regex  = true
    values = ["oke-*"]
  }
}
