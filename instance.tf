resource "oci_core_instance" "self" {
  display_name = local.instance_name

  shape = var.vm_shape
  shape_config {
    memory_in_gbs = var.vm_specs["memory"]
    ocpus         = var.vm_specs["cpus"]
  }
  source_details {
    source_id   = var.vm_image
    source_type = "image"
  }

  compartment_id                      = var.compartment_id
  availability_domain                 = var.availability_domain
  is_pv_encryption_in_transit_enabled = "true"
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }

  create_vnic_details {
    assign_private_dns_record = "true"
    assign_public_ip          = "true"
    nsg_ids                   = [oci_core_network_security_group.self[0].id]
    subnet_id                 = var.existing_pub_subnet == "" ? oci_core_subnet.public[0].id : var.existing_pub_subnet
  }


  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"
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

  metadata = {
    ssh_authorized_keys = var.pub_key
    # user_data           = base64encode(data.template_file.bootstrap.rendered)
  }
}