resource "oci_objectstorage_bucket" "self" {
  name = "${local.unique_resource_name}-backups"

  compartment_id = oci_identity_compartment.self.id
  namespace      = data.oci_objectstorage_namespace.self.namespace

  storage_tier = "Standard"

  freeform_tags = {
    project = var.project_name
  }
}