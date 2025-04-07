output "cluster_token" {
  value     = module.compute.cluster_token
  sensitive = true
}

output "cloud_init_user_data" {
  value = module.compute.cloud_init_user_data
}

output "cloud_init_user_data_base64" {
  value = base64encode(module.compute.cloud_init_user_data)
}
