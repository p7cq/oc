locals {
  ad = {
    "ad1" = data.oci_identity_availability_domain.ad1.name
    "ad2" = data.oci_identity_availability_domain.ad2.name
  }
  oc                  = jsondecode(file("${path.module}/${terraform.workspace}.json"))
  oc_output_directory = abspath("./artifacts")
  region_key          = element([for e in data.oci_identity_regions.this.regions : e if e.name == var.region], 0).key
}
