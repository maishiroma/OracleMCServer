resource "oci_core_vcn" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = local.unique_resource_name
  compartment_id = var.compartment_id
  cidr_block     = var.vpc_cidr_block
  dns_label      = "vcn05182201"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_core_subnet" "public" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name   = "${local.unique_resource_name}-public"
  compartment_id = var.compartment_id
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
  compartment_id = var.compartment_id

  vcn_id  = oci_core_vcn.self[count.index].id
  enabled = "true"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_core_default_route_table" "self" {
  count = var.existing_pub_subnet == "" ? 1 : 0

  display_name = local.unique_resource_name

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

  freeform_tags = {
    project = var.project_name
  }
}