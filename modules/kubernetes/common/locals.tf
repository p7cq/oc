locals {
  max_upload_size = "2048m"
  namespace       = "default"

  reset = {
    cert_manager  = false
    load_balancer = false
    nextcloud     = false
  }

  worker_hostname_map = { for w in try(data.oci_core_instances.this.instances.*.display_name, []) : split("-", w)[length(split("-", w)) - 1] => w }
}
