data "oci_identity_availability_domain" "ad1" {
  ad_number      = "1"
  compartment_id = var.tenancy_ocid
}

data "oci_identity_availability_domain" "ad2" {
  ad_number      = "2"
  compartment_id = var.tenancy_ocid
}

data "oci_identity_availability_domain" "ad3" {
  ad_number      = "3"
  compartment_id = var.tenancy_ocid
}

data "oci_identity_regions" "this" {}
