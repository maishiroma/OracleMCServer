locals {
  unique_resource_name = "${var.project_name}-${random_string.unique.result}"

  instance_name = "${local.unique_resource_name}-ins"
}

data "oci_objectstorage_namespace" "self" {
  compartment_id = var.compartment_id
}

resource "random_string" "unique" {
  length  = 5
  special = false
  upper   = false
}