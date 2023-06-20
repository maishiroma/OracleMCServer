terraform {
  required_version = "> 0.12"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "= 4.121.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "= 3.5.1"
    }

    template = {
      source  = "hashicorp/template"
      version = "= 2.2.0"
    }
  }
}