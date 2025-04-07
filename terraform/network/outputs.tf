output "vcn" {
  description = "Created VCN"
  value       = oci_core_vcn.cluster_network
}

output "cluster_subnet" {
  description = "Subnet of the k3s cluser"
  value       = oci_core_subnet.cluster_subnet
  depends_on  = [oci_core_subnet.cluster_subnet]
}

output "nsg_k3s_compute_instance" {
  description = "NSG for k3s compute nodes"
  value       = oci_core_network_security_group.k3s_compute_instance.id
}

output "nsg_public_ingress" {
  description = "NSG for public network access"
  value       = oci_core_network_security_group.public_ingress.id
}
