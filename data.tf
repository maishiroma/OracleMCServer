locals {
  unique_resource_name = "${var.project_name}-${random_string.unique.result}"
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
  }
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
          encoding    = "b64"
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