resource "oci_objectstorage_bucket" "self" {
  name = "${var.project_name}-backups"

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.self.namespace

  storage_tier = "Standard"
}