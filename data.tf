locals {
  unique_resource_name = "${var.project_name}-${random_string.unique.result}"

  server_properties_path = var.custom_server_properties_path == "" ? "${path.module}/templates/server.properties.tpl" : var.custom_server_properties_path
  ops_json_path          = var.custom_ops_json_path == "" ? "${path.module}/templates/ops.json.tpl" : var.custom_ops_json_path
}

data "oci_objectstorage_namespace" "self" {
  compartment_id = oci_identity_compartment.self.id
}

data "template_file" "fact_file" {
  template = file("${path.module}/templates/oci_facts.tpl")
  vars = {
    MIN_MEMORY              = var.min_memory
    MAX_MEMORY              = var.max_memory
    BUCKET_NAMESPACE        = data.oci_objectstorage_namespace.self.namespace
    BUCKET_NAME             = oci_objectstorage_bucket.self.name
    SERVER_JAR_DOWNLOAD_URL = var.minecraft_server_jar_download_url
    REGION_NAME             = var.region_name
    COMPARTMENT_ID          = oci_identity_compartment.self.id
    IS_MODDED               = var.is_modded
  }
}

data "template_file" "server_properties_file" {
  template = file(local.server_properties_path)
}

data "template_file" "ops_file" {
  template = file(local.ops_json_path)
}

data "template_cloudinit_config" "self" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      write_files = [
        {
          content     = data.template_file.fact_file.rendered
          path        = "/etc/oci_facts"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = data.template_file.server_properties_file.rendered
          path        = "/etc/server.properites"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = data.template_file.ops_file.rendered
          path        = "/etc/ops.json"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = file("${path.module}/scripts/bootstrap.sh")
          path        = "/etc/bootstrap.sh"
          owner       = "root:root"
          permissions = "0744"
        }
      ]
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/scripts/bootstrap.sh")
  }
}

resource "random_string" "unique" {
  length  = 5
  special = false
  upper   = false
}