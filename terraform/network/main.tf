terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_core_vcn" "cluster_network" {
  compartment_id = var.compartment_id

  cidr_blocks = var.cidr_blocks

  display_name = "cluster-vcn"
  dns_label    = "cluster"
}

resource "oci_core_default_security_list" "default_list" {
  manage_default_resource_id = oci_core_vcn.cluster_network.default_security_list_id

  display_name = "Outbound only (default)"

  egress_security_rules {
    protocol    = "all" // TCP
    description = "Allow outbound"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol    = "all"
    description = "Allow inter-subnet traffic"
    source      = var.cidr_blocks[0]
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.cluster_network.id
  enabled        = true
}

resource "oci_core_default_route_table" "internet_route_table" {
  compartment_id             = var.compartment_id
  manage_default_resource_id = oci_core_vcn.cluster_network.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "cluster_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.cluster_network.id
  cidr_block        = oci_core_vcn.cluster_network.cidr_blocks[0]
  display_name      = "cluster subnet"
  security_list_ids = [oci_core_vcn.cluster_network.default_security_list_id]
  dns_label         = "compute"
}

resource "oci_core_network_security_group" "k3s_compute_instance" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.cluster_network.id
  display_name   = "k3s Compute"
}

resource "oci_core_network_security_group_security_rule" "k3s_compute_instance_lb_ingress" {
  for_each = {
    TCP = "6"
    UDP = "17"
  }

  network_security_group_id = oci_core_network_security_group.k3s_compute_instance.id
  protocol                  = each.value
  source                    = oci_core_network_security_group.public_ingress.id
  source_type               = "NETWORK_SECURITY_GROUP"

  direction = "INGRESS"
}

resource "oci_core_network_security_group_security_rule" "k3s_compute_instance_ssh" {
  network_security_group_id = oci_core_network_security_group.k3s_compute_instance.id
  protocol                  = "6" // TCP
  source                    = var.ssh_management_network
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
  direction = "INGRESS"
}


resource "oci_core_network_security_group" "public_ingress" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.cluster_network.id
  display_name   = "Cluster Load Balancer"
}

resource "oci_core_network_security_group_security_rule" "public_ingress_kube_api" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.public_ingress.id
  protocol                  = "6" // TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "k8s cluster management"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "public_ingress_puffer_sftp" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.public_ingress.id
  protocol                  = "6" // TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "PufferPanel SFTP"

  tcp_options {
    destination_port_range {
      max = 5657
      min = 5657
    }
  }
}

resource "oci_core_network_security_group_security_rule" "public_ingress_minecraft" {
  for_each = {
    TCP = "6" 
    UDP = "17" 
  }

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.public_ingress.id
  protocol                  = each.value
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "Minecraft clients"

  dynamic "tcp_options" {
    for_each = each.key == "TCP" ? [25565] : []

    content {
      destination_port_range {
        max = tcp_options.value
        min = tcp_options.value
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.key == "UDP" ? [19132] : []

    content {
      destination_port_range {
        max = udp_options.value
        min = udp_options.value
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "public_ingress_http" {
  for_each = merge([
    for port in [80, 443] : {
      for cidr in data.cloudflare_ip_ranges.cloudflare.ipv4_cidr_blocks :
      "${cidr}:${port}" => {
        port   = port
        source = cidr
      }
    }
  ]...)

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.public_ingress.id
  protocol                  = "6" // TCP
  source_type               = "CIDR_BLOCK"
  source                    = each.value.source
  description               = "Ingress from Cloudflare"

  tcp_options {
    destination_port_range {
      max = each.value.port
      min = each.value.port
    }
  }
}
