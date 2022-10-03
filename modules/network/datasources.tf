data "oci_core_drgs" "this" {
  compartment_id = var.oc.compartment_ocid

  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }
}

data "oci_core_services" "this" {}
