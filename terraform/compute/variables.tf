variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "cluster_subnet_id" {
  description = "Subnet for the bastion instance"
  type        = string
}

variable "cluster_vault_id" {
  description = "KMS Vault ID for storing cluster secrets"
  type        = string
}

variable "cluster_master_key_id" {
  description = "KMS Vault master key ID for storing cluster secrets"
  type        = string
}

variable "ampere_ad_number" {
  description = "Availabiliby Domain number for Ampere instances"
  type        = number
}

variable "nsg_id" {
  description = "NSG to permit SSH"
  type        = string
}

variable "cluster_lb_san" {
  description = "The fixed IP/DNS of the cluster"
  type        = string
}

variable "cluster_lb_private_ip" {
  description = "The fixed IP/DNS of the cluster"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "List of authorized SSH keys"
  type        = list(string)
}

variable "oracle_linux_aarch64_image" {
  description = "Oracle Linux image description from https://docs.oracle.com/en-us/iaas/images/oracle-linux-9x/"
  default = "Oracle-Linux-9.5-aarch64-2025.01.31-0"
}

variable "oracle_linux_x86_64_image" {
  description = "Oracle Linux image description from https://docs.oracle.com/en-us/iaas/images/oracle-linux-9x/"
  default = "Oracle-Linux-9.5-Minimal-2025.01.31-0"
}
