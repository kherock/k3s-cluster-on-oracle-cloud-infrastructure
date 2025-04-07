terraform {
  required_version = "~> 1.2"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 6.30"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "oci" {
  config_file_profile = "DEFAULT"
  region              = var.region
}


locals {
  cidr_blocks            = ["10.0.0.0/24"]
  ssh_management_network = "0.0.0.0/0"
}

module "network" {
  source = "./network"

  compartment_id = var.compartment_id

  cidr_blocks            = local.cidr_blocks
  ssh_management_network = local.ssh_management_network
}

module "compute" {
  source = "./compute"

  cluster_lb_san = one([
    for entry in oci_network_load_balancer_network_load_balancer.public_ingress.ip_addresses : entry.ip_address
    if entry.is_public
  ])

  cluster_lb_private_ip = one([
    for entry in oci_network_load_balancer_network_load_balancer.public_ingress.ip_addresses : entry.ip_address
    if !entry.is_public
  ])

  compartment_id        = var.compartment_id
  cluster_subnet_id     = module.network.cluster_subnet.id
  cluster_vault_id      = module.vault.vault_id
  cluster_master_key_id = module.vault.master_key_id
  ampere_ad_number      = var.ampere_ad_number
  nsg_id                = module.network.nsg_k3s_compute_instance
  ssh_authorized_keys   = compact(concat(
    try(split("\n", file(pathexpand("~/.ssh/authorized_keys"))), []),
    [
      try(trimspace(file(pathexpand("~/.ssh/id_ed25519.pub"))), ""),
      try(trimspace(file(pathexpand("~/.ssh/id_rsa.pub"))), ""),
    ]
  ))
}

module "vault" {
  source = "./vault"

  compartment_id = var.compartment_id
}

resource "oci_identity_dynamic_group" "compartment_instances" {
  compartment_id = var.compartment_id
  name           = "All-Compartment-Instances"
  description    = "Compartment instances"
  matching_rule  = "Any {instance.compartment.id = '${var.compartment_id}'}"
}

resource "oci_identity_policy" "k3s_compute_execution" {
  compartment_id = var.compartment_id
  name           = "k3s-compute-execution"
  description    = "K3S compute execution policy"
  statements = [
    "Allow dynamic-group 'Default'/'${oci_identity_dynamic_group.compartment_instances.name}' to use secret-family in tenancy"
  ]
}
