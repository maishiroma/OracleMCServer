resource "oci_core_vcn" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  compartment_id = var.compartment_id

  display_name = var.project_name
  dns_label    = "vcn05182201"
  cidr_block   = var.vpc_cidr_block
}

resource "oci_core_subnet" "public" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.self[count.index].id

  display_name = "${var.project_name}-public"
  dns_label    = "subnet05182201"

  cidr_block     = var.pub_subnet_block
  route_table_id = oci_core_vcn.self[count.index].default_route_table_id
}

resource "oci_core_internet_gateway" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "Internet Gateway ${var.project_name}"

  vcn_id  = oci_core_vcn.self[count.index].id
  enabled = "true"
}

resource "oci_core_default_route_table" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.self[count.index].id
  }
  manage_default_resource_id = oci_core_vcn.self[count.index].default_route_table_id
}

resource "oci_core_network_security_group" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.self[count.index].id

  display_name = var.project_name
}

resource "oci_core_network_security_group_security_rule" "admin" {
  count = var.existing_pub_subnet == "" ? length(var.admin_ip_addresses) : 0

  network_security_group_id = oci_core_network_security_group.self[count.index].id
  direction                 = "INGRESS"
  protocol                  = "6"

  source_type = "CIDR_BLOCK"
  source      = var.admin_ip_addresses[count.index]

  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
    source_port_range {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "game" {
  count = var.existing_pub_subnet == "" ? length(var.game_ip_addresses) : 0

  network_security_group_id = oci_core_network_security_group.self[count.index].id
  direction                 = "INGRESS"
  protocol                  = "6"

  source_type = "CIDR_BLOCK"
  source      = var.game_ip_addresses[count.index]

  tcp_options {
    destination_port_range {
      max = 25565
      min = 25565
    }
    source_port_range {
      max = 25565
      min = 25565
    }
  }
}

resource "oci_core_network_security_group_security_rule" "engress" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  network_security_group_id = oci_core_network_security_group.self[count.index].id
  direction                 = "EGRESS"
  protocol                  = "all"

  destination_type = "CIDR_BLOCK"
  destination      = "0.0.0.0/0"
}