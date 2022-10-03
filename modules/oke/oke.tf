resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.oc.compartment_ocid
  kubernetes_version = join("", ["v", var.oc.version.kubernetes])
  name               = join("-", [var.oc.name, "cluster"])
  vcn_id             = var.vcn_ocid

  endpoint_config {
    is_public_ip_enabled = "false"
    subnet_id            = var.api_subnet_ocid
  }

  options {
    kubernetes_network_config {
      pods_cidr     = "10.1.0.0/16"
      services_cidr = "10.2.0.0/16"
    }
    service_lb_subnet_ids = [var.lb_subnet_ocid]
  }
}

resource "oci_containerengine_node_pool" "this" {
  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.oc.compartment_ocid
  kubernetes_version = join("", ["v", var.oc.version.kubernetes])
  name               = local.oke_label_map["name"]
  node_metadata      = { user_data = data.cloudinit_config.this.rendered }
  node_shape         = local.oke_node_shape
  ssh_public_key     = base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)

  dynamic "initial_node_labels" {
    for_each = local.oke_label_map

    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  node_config_details {
    dynamic "placement_configs" {
      for_each = var.ad
      content {
        availability_domain = placement_configs.value
        subnet_id           = var.worker_subnet_ocid
      }
    }
    size = length(var.ad)
  }

  node_shape_config {
    memory_in_gbs = 24
    ocpus         = 6
  }

  node_source_details {
    boot_volume_size_in_gbs = 200
    image_id                = lookup(local.latest_image, reverse(keys(local.latest_image))[0], "not_found").source_image_ocid
    source_type             = "IMAGE"
  }
}
