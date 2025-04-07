terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_kms_vault" "cluster" {
  compartment_id = var.compartment_id
  display_name   = "cluster"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "master" {
  compartment_id      = var.compartment_id
  display_name        = "master"
  management_endpoint = oci_kms_vault.cluster.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}
