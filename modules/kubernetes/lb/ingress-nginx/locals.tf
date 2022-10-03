locals {
  controller_set = [
    {
      name  = "controller.config.ssl-protocols"
      value = "TLSv1.3"
    },
    {
      name  = "controller.extraArgs.default-ssl-certificate"
      value = join("/", [var.namespace, var.ingress_secret_name])
    },
    {
      name  = "controller.kind"
      value = "DaemonSet"
    },
    {
      name  = "controller.replicaCount"
      value = length(var.worker_hostname_map)
    },
    {
      name  = "controller.service.loadBalancerIP"
      value = var.load_balancer_ip
    },
    {
      name  = "controller.service.externalTrafficPolicy"
      value = "Local"
    },
    {
      name  = "controller.service.annotations.oci\\.oraclecloud\\.com/load-balancer-type"
      value = "nlb"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape"
      value = "flexible"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape-flex-max"
      value = "10"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape-flex-min"
      value = "10"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.oci-load-balancer\\.oraclecloud\\.com/security-list-management-mode"
      value = "None"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.oci-network-load-balancer\\.oraclecloud\\.com/internal"
      value = "false"
      type  = "string"
    }
  ]
}
