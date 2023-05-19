resource "oci_core_vcn" "self" {
  compartment_id = var.compartment_id

  display_name = var.project_name
  dns_label    = "vcn05182201"
  cidr_block   = var.vpc_cidr_block
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.self.id

  display_name = "${var.project_name}-public"
  dns_label    = "subnet05182201"

  cidr_block     = var.pub_subnet_block
  route_table_id = oci_core_vcn.self.default_route_table_id
}

resource "oci_core_internet_gateway" "self" {
  compartment_id = var.compartment_id
  display_name   = "Internet Gateway ${var.project_name}"

  vcn_id  = oci_core_vcn.self.id
  enabled = "true"
}

resource "oci_core_default_route_table" "self" {
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.self.id
  }
  manage_default_resource_id = oci_core_vcn.self.default_route_table_id
}
