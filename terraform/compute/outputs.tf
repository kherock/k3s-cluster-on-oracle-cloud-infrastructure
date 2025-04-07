output "cluster_token" {
  value     = random_password.cluster_token.result
  sensitive = true
}

output "cloud_init_user_data" {
  value = local.user_data
}

output "ubuntu_images" {
  value = data.oci_core_images.ubuntu_minimal
}

output "k8s_apiserver_nodes" {
  value = {
    for instance in concat(oci_core_instance.epyc[*], oci_core_instance.ampere[*]) :
    instance.display_name => instance
  }
}

output "k8s_agent_nodes" {
  value = {
    for instance in concat(oci_core_instance.epyc[*], oci_core_instance.ampere[*]) :
    instance.display_name => instance
  }
}
