resource "oci_identity_dynamic_group" "self" {
  compartment_id = var.compartment_id

  name          = local.unique_resource_name
  description   = "MC Servers"
  matching_rule = "ALL {instance.compartment.id = '${var.compartment_id}'}"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_identity_policy" "self" {
  compartment_id = var.compartment_id
  name           = local.unique_resource_name
  description    = "Policy to allow access to buckets"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.self.name} to manage objects in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.self.name} to manage buckets in tenancy"
  ]

  freeform_tags = {
    project = var.project_name
  }
}