data "oci_core_images" "ubuntu_minimal" {
  for_each = {
    x86_64  = "22.04 Minimal"
    aarch64 = "22.04 Minimal aarch64"
  }

  compartment_id = var.compartment_id

  operating_system         = "Canonical Ubuntu"
  operating_system_version = each.value
  sort_by                  = "TIMECREATED"
  state                    = "AVAILABLE"
}

data "oci_core_images" "oracle_linux" {
  for_each = {
    x86_64  = var.oracle_linux_x86_64_image
    aarch64 = var.oracle_linux_aarch64_image
  }

  compartment_id = var.compartment_id

  display_name     = each.value
  sort_by          = "TIMECREATED"
  state            = "AVAILABLE"
}

data "oci_identity_availability_domain" "ad" {
  for_each = toset(["1", "2", "3"])

  compartment_id = var.compartment_id
  ad_number      = each.key
}
