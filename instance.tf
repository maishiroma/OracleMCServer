resource "oci_core_instance_configuration" "self" {
  compartment_id = oci_identity_compartment.self.id
  display_name   = local.unique_resource_name

  instance_details {
    instance_type = "compute"

    launch_details {
      availability_domain                 = var.availability_domain
      compartment_id                      = oci_identity_compartment.self.id
      is_pv_encryption_in_transit_enabled = true
      metadata = {
        "ssh_authorized_keys" = var.pub_key
        "user_data"           = data.template_cloudinit_config.self.rendered
      }
      shape = var.vm_shape

      agent_config {
        are_all_plugins_disabled = false
        is_management_disabled   = false
        is_monitoring_disabled   = false

        plugins_config {
          desired_state = "DISABLED"
          name          = "Vulnerability Scanning"
        }
        plugins_config {
          desired_state = "DISABLED"
          name          = "Oracle Java Management Service"
        }
        plugins_config {
          desired_state = "ENABLED"
          name          = "OS Management Service Agent"
        }
        plugins_config {
          desired_state = "ENABLED"
          name          = "Compute Instance Run Command"
        }
        plugins_config {
          desired_state = "ENABLED"
          name          = "Compute Instance Monitoring"
        }
        plugins_config {
          desired_state = "DISABLED"
          name          = "Block Volume Management"
        }
        plugins_config {
          desired_state = "DISABLED"
          name          = "Bastion"
        }
      }

      availability_config {
        recovery_action = "RESTORE_INSTANCE"
      }

      create_vnic_details {
        assign_private_dns_record = true
        assign_public_ip          = true
        defined_tags              = {}
        freeform_tags             = {}
        nsg_ids                   = []
        skip_source_dest_check    = false
        subnet_id                 = var.existing_pub_subnet == "" ? oci_core_subnet.public[0].id : var.existing_pub_subnet
      }

      instance_options {
        are_legacy_imds_endpoints_disabled = false
      }

      # Only use this if we are using the Free Tier Image Size
      dynamic "shape_config" {
        for_each = var.vm_shape == "VM.Standard.A1.Flex" ? ["1"] : []
        content {
          memory_in_gbs = var.vm_specs["memory"]
          ocpus         = var.vm_specs["cpus"]
        }
      }

      # Only use this if we are NOT using the Free Tier Image
      dynamic "shape_config" {
        for_each = var.vm_shape != "VM.Standard.A1.Flex" ? ["1"] : []
        content {
          memory_in_gbs             = var.vm_specs["memory"]
          ocpus                     = var.vm_specs["cpus"]
          baseline_ocpu_utilization = "BASELINE_1_8"
        }
      }

      source_details {
        image_id    = var.vm_image
        source_type = "image"
      }
    }
  }

  freeform_tags = {
    project = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_core_instance_pool" "self" {
  compartment_id = oci_identity_compartment.self.id
  display_name   = local.unique_resource_name
  size           = 1

  instance_configuration_id = oci_core_instance_configuration.self.id
  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = var.existing_pub_subnet == "" ? oci_core_subnet.public[0].id : var.existing_pub_subnet
  }

  freeform_tags = {
    project = var.project_name
  }
}