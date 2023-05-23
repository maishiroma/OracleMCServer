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

  security_list_ids = [oci_core_security_list.self[count.index].id]
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

resource "oci_core_security_list" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = var.project_name
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.self[count.index].id

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

  dynamic "ingress_security_rules" {
    for_each = var.admin_ip_addresses
    content {
      protocol    = "6"
      source_type = "CIDR_BLOCK"
      source      = ingress_security_rules.value
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.game_ip_addresses
    content {
      protocol    = "6"
      source_type = "CIDR_BLOCK"
      source      = ingress_security_rules.value
      tcp_options {
        max = 25565
        min = 25565
      }
    }
  }
}