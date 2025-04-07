terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

locals {
  user_data = templatefile("${path.module}/templates/oci-cloud-init.sh", {
    vault_id = var.cluster_vault_id
  })
}

resource "oci_core_instance" "epyc" {
  count = 0

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad[3].name
  display_name        = "k3s_epyc_${count.index}"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_id   = data.oci_core_images.oracle_linux["x86_64"].images[0].id
    source_type = "image"

    boot_volume_size_in_gbs = 50
  }
  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  create_vnic_details {
    subnet_id = var.cluster_subnet_id
    nsg_ids   = [var.nsg_id]
    assign_public_ip = false
  }
  metadata = {
    ssh_authorized_keys = join("\n", var.ssh_authorized_keys)
    user_data           = base64encode(local.user_data)
  }

  preserve_boot_volume = true

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
      metadata,
    ]
  }
}

resource "oci_core_instance" "ampere" {
  count = 1

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad[var.ampere_ad_number].name
  display_name        = "k3s_ampere_${count.index}"

  shape = "VM.Standard.A1.Flex"

  source_details {
    source_id   = data.oci_core_images.oracle_linux["aarch64"].images[0].id
    source_type = "image"
  }
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }
  create_vnic_details {
    subnet_id = var.cluster_subnet_id
    nsg_ids   = [var.nsg_id]
    assign_public_ip = false
  }

  metadata = {
    ssh_authorized_keys = join("\n", var.ssh_authorized_keys)
    user_data           = base64encode(local.user_data)
  }

  preserve_boot_volume = true

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
      metadata,
    ]
  }
}
