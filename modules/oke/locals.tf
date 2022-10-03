locals {
  latest_image = {
    for s in data.oci_containerengine_node_pool_option.this.sources : split("-", s.source_name)[length(split("-", s.source_name)) - 1] =>
    {
      source_image_name = s.source_name
      source_image_ocid = s.image_id
    } if length(var.oc.version.kubernetes) > 0 &&
    s.source_name == try(regex(join(".*", [replace(join("-", ["Oracle Linux", var.oc.version.oracle_linux, "aarch64", "\\d{4}.\\d{2}.\\d{2}"]), " ", "-"), "-OKE-${var.oc.version.kubernetes}.*"]), s.source_name), "not_found")
  }

  oke_label_map              = { "name" = join("-", [var.oc.name, "node-pool"]) }
  oke_node_shape             = "VM.Standard.A1.Flex"
  ssh_public_key_secret_name = "oke-worker-ssh-public"
  template                   = templatefile("${path.module}/template/cloud-init/oke.tpl", {})
}
