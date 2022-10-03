data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = var.oke_ocid
}
