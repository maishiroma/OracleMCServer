resource "oci_objectstorage_bucket" "self" {
  name = "${local.unique_resource_name}-backups"

  compartment_id = oci_identity_compartment.self.id
  namespace      = data.oci_objectstorage_namespace.self.namespace

  storage_tier = "Standard"

  freeform_tags = {
    project = var.project_name
  }

  depends_on = [
    data.oci_objectstorage_namespace.self
  ]
}

resource "oci_objectstorage_object_lifecycle_policy" "self" {
  bucket    = oci_objectstorage_bucket.self.name
  namespace = data.oci_objectstorage_namespace.self.namespace

  rules {
    action      = "DELETE"
    is_enabled  = true
    name        = "delete_older_backups"
    target      = "objects"
    time_amount = "30"
    time_unit   = "DAYS"

    object_name_filter {
      inclusion_patterns = [
        "*.zip",
      ]
    }
  }

  depends_on = [
    data.oci_objectstorage_namespace.self
  ]
}

resource "oci_objectstorage_object" "bootstrap_config" {
  bucket    = oci_objectstorage_bucket.self.name
  namespace = data.oci_objectstorage_namespace.self.namespace

  source      = data.archive_file.bootstrap_config.output_path
  object      = local.bootstrap_config_zip_prefix
  content_md5 = data.archive_file.bootstrap_config.output_md5
}