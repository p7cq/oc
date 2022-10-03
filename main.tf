module "network" {
  source = "./modules/network"

  oc         = local.oc
  region_key = local.region_key
}

module "oke" {
  source = "./modules/oke"

  ad                   = local.ad
  api_subnet_ocid      = module.network.oke_api_subnet_ocid
  lb_subnet_ocid       = module.network.oke_lb_subnet_ocid
  vcn_ocid             = module.network.vcn_ocid
  worker_subnet_ocid   = module.network.oke_worker_subnet_ocid
  oc                   = local.oc
  oc_output_directory  = local.oc_output_directory
}

module "bastion" {
  source = "./modules/bastion"

  oc                    = local.oc
  oke_api_endpoint_host = module.oke.private_endpoint_host
  oke_api_endpoint_port = module.oke.private_endpoint_port
  subnet_ocid           = module.network.bastion_subnet_ocid
}

module "kubeconfig" {
  source = "./modules/kubeconfig"

  oc                    = local.oc
  oc_output_directory   = local.oc_output_directory
  oke_ocid              = module.oke.ocid
  oke_api_endpoint_host = module.oke.private_endpoint_host
  oke_api_endpoint_port = module.oke.private_endpoint_port
  region                = var.region
  bastion_session_ocid  = module.bastion.session_ocid
}

module "kubernetes_common" {
  source = "./modules/kubernetes/common"

  oc = local.oc
}

module "kubernetes_cert_manager" {
  source = "./modules/kubernetes/cert-manager"

  issuer               = module.kubernetes_common.issuer
  namespace            = module.kubernetes_common.namespace
  oc                   = local.oc
  reset                = module.kubernetes_common.reset.cert_manager
}

module "kubernetes_lb" {
  source = "./modules/kubernetes/lb/ingress-nginx"

  ingress_secret_name   = module.kubernetes_common.ingress_secret_name
  load_balancer_ip      = module.network.oke_lb_reserved_ip
  max_upload_size       = module.kubernetes_common.max_upload_size
  namespace             = module.kubernetes_common.namespace
  oc                    = local.oc
  reset                 = module.kubernetes_common.reset.load_balancer
  worker_hostname_map   = module.kubernetes_common.worker_hostname_map
}

module "kubernetes_oc" {
  source = "./modules/kubernetes/oc"

  ingress_secret_name = module.kubernetes_common.ingress_secret_name
  issuer              = module.kubernetes_common.issuer
  load_balancer_ip    = module.network.oke_lb_reserved_ip
  load_balancer_cidr  = module.network.oke_lb_subnet_cidr
  max_upload_size     = module.kubernetes_common.max_upload_size
  namespace           = module.kubernetes_common.namespace
  oc                  = local.oc
  oc_output_directory = local.oc_output_directory
  reset               = module.kubernetes_common.reset.nextcloud
  worker_hostname_map = module.kubernetes_common.worker_hostname_map
}
