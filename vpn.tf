resource "oci_core_vcn" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = local.unique_resource_name
  compartment_id = oci_identity_compartment.self.id
  cidr_block     = var.vpc_cidr_block
  dns_label      = "vcn05182201"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_core_subnet" "public" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = "${local.unique_resource_name}-public"
  compartment_id = oci_identity_compartment.self.id
  cidr_block     = var.pub_subnet_block
  dns_label      = "subnet05182201"

  vcn_id            = oci_core_vcn.self[count.index].id
  route_table_id    = oci_core_vcn.self[count.index].default_route_table_id
  security_list_ids = [oci_core_security_list.self[count.index].id]

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_core_internet_gateway" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = local.unique_resource_name
  compartment_id = oci_identity_compartment.self.id

  vcn_id  = oci_core_vcn.self[count.index].id
  enabled = "true"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_core_default_route_table" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = local.unique_resource_name
  compartment_id = oci_identity_compartment.self.id

  manage_default_resource_id = oci_core_vcn.self[count.index].default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.self[count.index].id
  }

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_core_security_list" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = local.unique_resource_name
  compartment_id = oci_identity_compartment.self.id
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

      dynamic "tcp_options" {
        for_each = local.game_tcp_ports
        content {
          max = tcp_options.value
          min = tcp_options.value
        }
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = length(var.additonal_udp_ports) == 0 ? [] : var.game_ip_addresses
    content {
      protocol    = "17"
      source_type = "CIDR_BLOCK"
      source      = ingress_security_rules.value

      dynamic "udp_options" {
        for_each = var.additonal_udp_ports
        content {
          max = udp_options.value
          min = udp_options.value
        }
      }
    }
  }

  freeform_tags = {
    project = var.project_name
  }
}