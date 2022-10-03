resource "oci_core_vcn" "this" {
  cidr_blocks    = [var.oc.vcn_cidr_block]
  compartment_id = var.oc.compartment_ocid
  display_name   = var.oc.name
  dns_label      = var.oc.name
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.oc.compartment_ocid
  display_name   = join("-", [var.oc.name, "ig"])
  vcn_id         = oci_core_vcn.this.id
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.oc.compartment_ocid
  display_name   = join("-", [var.oc.name, "ng"])
  vcn_id         = oci_core_vcn.this.id
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.oc.compartment_ocid
  display_name   = join("-", [var.oc.name, "sg"])
  vcn_id         = oci_core_vcn.this.id

  services {
    service_id = local.oci_service.ocid
  }
}

resource "oci_core_drg_attachment" "this" {
  display_name = join("-", [var.oc.name, "drg-attachment"])
  drg_id       = data.oci_core_drgs.this.drgs.0.id
  vcn_id       = oci_core_vcn.this.id
}

resource "oci_core_route_table" "bastion_public" {
  count = var.oc.bastion.enabled ? 1 : 0

  compartment_id = var.oc.compartment_ocid
  display_name   = "bastion-public-rt"
  vcn_id         = oci_core_vcn.this.id

  route_rules {
    destination       = local.anywhere
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_route_table" "oke_private" {
  compartment_id = var.oc.compartment_ocid
  display_name   = "oke-private-rt"
  vcn_id         = oci_core_vcn.this.id

  route_rules {
    destination       = local.anywhere
    network_entity_id = oci_core_nat_gateway.this.id
  }

  route_rules {
    destination       = local.oci_service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }

  route_rules {
    description       = "Route to LAN"
    destination       = var.oc.lan_cidr_block
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_drgs.this.drgs.0.id
  }
}

resource "oci_core_route_table" "oke_public" {
  compartment_id = var.oc.compartment_ocid
  display_name   = "oke-public-rt"
  vcn_id         = oci_core_vcn.this.id

  route_rules {
    destination       = local.anywhere
    network_entity_id = oci_core_internet_gateway.this.id
  }

  route_rules {
    description       = "Route to LAN (LB private IP)"
    destination       = var.oc.lan_cidr_block
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_drgs.this.drgs.0.id
  }
}

# Security list

resource "oci_core_default_security_list" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id
}

resource "oci_core_security_list" "bastion" {
  count = var.oc.bastion.enabled ? 1 : 0

  compartment_id = var.oc.compartment_ocid
  display_name   = "bastion-sl"
  vcn_id         = oci_core_vcn.this.id

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_api_oke)
    protocol    = local.tcp

    tcp_options {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_security_list" "oke_worker" {
  compartment_id = var.oc.compartment_ocid
  display_name   = "oke-worker-sl"
  vcn_id         = oci_core_vcn.this.id

  ingress_security_rules {
    protocol = "all"
    source   = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)
  }

  ingress_security_rules {
    protocol = local.icmp
    source   = local.anywhere
    icmp_options {
      code = 4
      type = 3
    }
  }

  ingress_security_rules {
    protocol = local.tcp
    source   = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_api_oke)
  }

  ingress_security_rules {
    protocol = local.tcp
    source   = local.anywhere
  }

  ingress_security_rules {
    protocol = local.tcp
    source   = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_lb_oke)
    tcp_options {
      max = local.oke_worker_node_port_max
      min = local.oke_worker_node_port_min
    }
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oc.lan_cidr_block
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)
    protocol    = "all"
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_api_oke)
    protocol    = local.tcp

    tcp_options {
      max = 6443
      min = 6443
    }
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_api_oke)
    protocol    = local.tcp

    tcp_options {
      max = 12250
      min = 12250
    }
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_api_oke)
    protocol    = local.icmp

    icmp_options {
      code = 4
      type = 3
    }
  }

  egress_security_rules {
    destination      = local.oci_service.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = local.tcp

    tcp_options {
      max = 443
      min = 443
    }
  }

  egress_security_rules {
    destination = local.anywhere
    protocol    = local.icmp
    icmp_options {
      code = 4
      type = 3
    }
  }

  egress_security_rules {
    destination = local.anywhere
    protocol    = "all"
  }
}

resource "oci_core_security_list" "oke_api" {
  compartment_id = var.oc.compartment_ocid
  display_name   = "oke-api-sl"
  vcn_id         = oci_core_vcn.this.id

  ingress_security_rules {
    protocol = local.tcp
    source   = local.anywhere

    tcp_options {
      max = 6443
      min = 6443
    }
  }

  ingress_security_rules {
    protocol = local.tcp
    source   = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)

    tcp_options {
      max = 6443
      min = 6443
    }
  }

  ingress_security_rules {
    protocol = local.tcp
    source   = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)

    tcp_options {
      max = 12250
      min = 12250
    }
  }

  ingress_security_rules {
    protocol = local.icmp
    source   = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)

    icmp_options {
      code = 4
      type = 3
    }
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oc.lan_cidr_block
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)
    protocol    = local.icmp

    icmp_options {
      code = 4
      type = 3
    }
  }

  egress_security_rules {
    destination      = local.oci_service.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = local.tcp

    tcp_options {
      max = 443
      min = 443
    }
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)
    protocol    = local.tcp
  }
}

resource "oci_core_security_list" "oke_lb" {
  compartment_id = var.oc.compartment_ocid
  display_name   = "oke-lb-sl"
  vcn_id         = oci_core_vcn.this.id

  ingress_security_rules {
    protocol = local.tcp
    source   = local.anywhere

    tcp_options {
      max = 443
      min = 443
    }
  }

  ingress_security_rules {
    protocol = local.tcp
    source   = local.anywhere

    tcp_options {
      max = 80
      min = 80
    }
  }

  egress_security_rules {
    destination = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)
    protocol    = local.tcp

    tcp_options {
      max = local.oke_worker_node_port_max
      min = local.oke_worker_node_port_min
    }
  }
}

# Subnet

resource "oci_core_subnet" "bastion_public" {
  count = var.oc.bastion.enabled ? 1 : 0

  cidr_block                = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_bastion)
  compartment_id            = var.oc.compartment_ocid
  display_name              = "bastion-public"
  dns_label                 = "public"
  prohibit_internet_ingress = false
  route_table_id            = oci_core_route_table.bastion_public[0].id
  security_list_ids         = [oci_core_security_list.bastion[0].id]
  vcn_id                    = oci_core_vcn.this.id
}

resource "oci_core_subnet" "oke_worker_private" {
  cidr_block                = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_worker_oke)
  compartment_id            = var.oc.compartment_ocid
  display_name              = "oke-worker-private"
  dns_label                 = "worker"
  prohibit_internet_ingress = true
  route_table_id            = oci_core_route_table.oke_private.id
  security_list_ids         = [oci_core_security_list.oke_worker.id]
  vcn_id                    = oci_core_vcn.this.id
}

resource "oci_core_subnet" "oke_api_private" {
  cidr_block                = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_api_oke)
  compartment_id            = var.oc.compartment_ocid
  display_name              = "oke-api-private"
  dns_label                 = "api"
  prohibit_internet_ingress = true
  route_table_id            = oci_core_route_table.oke_private.id
  security_list_ids         = [oci_core_security_list.oke_api.id]
  vcn_id                    = oci_core_vcn.this.id
}

resource "oci_core_subnet" "oke_lb_public" {
  cidr_block                = cidrsubnet(var.oc.vcn_cidr_block, local.subnet_bit, local.netnum_lb_oke)
  compartment_id            = var.oc.compartment_ocid
  display_name              = "oke-lb-public"
  dns_label                 = "lb"
  prohibit_internet_ingress = false
  route_table_id            = oci_core_route_table.oke_public.id
  security_list_ids         = [oci_core_security_list.oke_lb.id]
  vcn_id                    = oci_core_vcn.this.id
}

resource "oci_core_public_ip" "this" {
  compartment_id = var.oc.compartment_ocid
  display_name   = "oke-lb-reserved-ip"
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}
