locals {
  anywhere = "0.0.0.0/0"
  icmp     = "1"
  tcp      = "6"
  udp      = "17"

  oke_worker_node_port_max = 32767
  oke_worker_node_port_min = 30000

  subnet_bit = 3

  netnum_api_oke    = 0
  netnum_bastion    = 3
  netnum_lb_oke     = 1
  netnum_worker_oke = 2

  oci_service = element(flatten([
    for e in data.oci_core_services.this.services : {
      ocid       = e.id
      cidr_block = e.cidr_block
    } if e.name == join(" ", ["All", var.region_key, "Services In Oracle Services Network"])
  ]), 0)
}
