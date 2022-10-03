resource "local_file" "kubeconfig" {
  content         = data.oci_containerengine_cluster_kube_config.this.content
  filename        = join("/", [var.oc_output_directory, "kube.config"])
  file_permission = "400"
}

resource "local_file" "kubeconfig_tunnel" {
  count = var.oc.bastion.enabled ? 1 : 0

  content = replace(
    replace(
      data.oci_containerengine_cluster_kube_config.this.content,
      join(":", [var.oke_api_endpoint_host, var.oke_api_endpoint_port]),
      join(":", ["localhost", var.oc.bastion.local_port])
    ),
    "/certificate-authority-data: .*/",
    "insecure-skip-tls-verify: true"
  )
  filename = join("/", [var.oc_output_directory, "local", "kube.config"])
}

resource "local_file" "ssh_tunnel" {
  count = var.oc.bastion.enabled ? 1 : 0

  content = templatefile("${path.module}/template/tunnel.tpl", {
    local_port       = var.oc.bastion.local_port
    private_key_path = var.oc.bastion.local_private_key_path
    ssh_host         = join(".", ["host.bastion", var.region, "oci.oraclecloud.com"])
    ssh_user         = var.bastion_session_ocid
    target_host      = var.oke_api_endpoint_host
    target_port      = var.oke_api_endpoint_port
    tunnel_log       = join("/", [var.oc_output_directory, "local", "tunnel.log"])
  })
  filename        = join("/", [var.oc_output_directory, "local", "tunnel.sh"])
  file_permission = "0555"
}

resource "null_resource" "open_ssh_tunnel" {
  count = var.oc.bastion.enabled ? 1 : 0

  provisioner "local-exec" {
    command = join(" ", [join("/", [var.oc_output_directory, "local", "tunnel.sh"]), "open"])
  }

  depends_on = [local_file.ssh_tunnel]
}
