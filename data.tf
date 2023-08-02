locals {
  unique_resource_name = "${var.project_name}-${random_string.unique.result}"

  server_properties_path = var.custom_server_properties_path == "" ? "${path.module}/templates/server.properties.tpl" : var.custom_server_properties_path
  ops_json_path          = var.custom_ops_json_path == "" ? "${path.module}/templates/ops.json.tpl" : var.custom_ops_json_path

  home_folder       = "/home/minecraft"
  server_folder     = "${local.home_folder}/server"
  mod_folder        = "${local.server_folder}/mods"
  service_name      = "minecraft"
  full_service_name = var.is_modded == false ? "Minecraft Server" : "Minecraft Modded Server"

  jar_name    = basename(var.minecraft_server_jar_download_url)
  run_command = var.is_modded == false ? "/usr/bin/java -Xms${var.min_memory} -Xmx${var.max_memory} -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -jar ${local.jar_name} nogui" : "/bin/sh run.sh"
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
    HOME_FOLDER             = local.home_folder
    SERVER_FOLDER           = local.server_folder
    MOD_FOLDER              = local.mod_folder
    SERVICE_NAME            = local.service_name
    JAR_NAME                = local.jar_name
  }
}

data "template_file" "minecraft_service" {
  template = file("${path.module}/templates/minecraft.service.tpl")

  vars = {
    server_folder     = "/home/minecraft/server"
    run_command       = local.run_command
    full_service_name = local.full_service_name
  }
}

data "template_file" "rclone_conf" {
  template = file("${path.module}/templates/rclone.conf.tpl")

  vars = {
    bucket_namespace = data.oci_objectstorage_namespace.self.namespace
    compartment_id   = oci_identity_compartment.self.id
    region_name      = var.region_name
  }
}

data "template_file" "modded_user_jvm_args" {
  template = file("${path.module}/templates/user_jvm_args.txt.tpl")

  vars = {
    min_memory = var.min_memory
    max_memory = var.max_memory
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
          content     = file(local.server_properties_path)
          path        = "/etc/server.properites"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = file(local.ops_json_path)
          path        = "/etc/ops.json"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = data.template_file.rclone_conf.rendered
          path        = "/etc/rclone.conf"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = data.template_file.modded_user_jvm_args.rendered
          path        = "/etc/user_jvm_args.txt"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = data.template_file.minecraft_service.rendered
          path        = "/etc/minecraft.service"
          owner       = "root:root"
          permissions = "0644"
        },
        {
          content     = file("${path.module}/scripts/backup.sh")
          path        = "/etc/backup.sh"
          owner       = "root:root"
          permissions = "0744"
        },
        {
          content     = file("${path.module}/scripts/restore_backup.sh")
          path        = "/etc/restore_backup.sh"
          owner       = "root:root"
          permissions = "0744"
        },
        {
          content     = file("${path.module}/scripts/mod_refresh.sh")
          path        = "/etc/mod_refresh.sh"
          owner       = "root:root"
          permissions = "0744"
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

data "oci_core_instance_pool_instances" "self" {
  compartment_id   = oci_identity_compartment.self.id
  instance_pool_id = oci_core_instance_pool.self.id
}

data "oci_core_instance" "self" {
  instance_id = data.oci_core_instance_pool_instances.self.instances[0].id
}