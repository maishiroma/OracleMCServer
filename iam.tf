resource "oci_identity_compartment" "self" {
  compartment_id = var.parent_compartment_id

  name        = local.unique_resource_name
  description = "The compartment that is associated with this deployment"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_identity_dynamic_group" "self" {
  compartment_id = var.parent_compartment_id

  name          = local.unique_resource_name
  description   = "MC Servers"
  matching_rule = "ALL {instance.compartment.id = '${oci_identity_compartment.self.id}'}"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_identity_policy" "self" {
  compartment_id = var.parent_compartment_id

  name        = "${local.unique_resource_name}-instances"
  description = "Policy to allow access to buckets"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.self.name} to manage objects in compartment ${oci_identity_compartment.self.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.self.name} to manage buckets in compartment ${oci_identity_compartment.self.name}"
  ]

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_identity_policy" "bucket_service" {
  compartment_id = var.parent_compartment_id

  name        = "${local.unique_resource_name}-bucket"
  description = "Policy to allow bucket service to manage objects in bucket"
  statements = [
    "Allow service objectstorage-${var.region_name} to manage object-family in compartment ${local.unique_resource_name}"
  ]

  freeform_tags = {
    project = var.project_name
  }
}