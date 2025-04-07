resource "random_password" "cluster_token" {
  length = 48
}

resource "oci_vault_secret" "k3s_token" {
  compartment_id = var.compartment_id
  vault_id       = var.cluster_vault_id
  key_id         = var.cluster_master_key_id
  secret_name    = "k3s-token"
  description    = "Shared secret used to join a server or agent to a cluster"

  secret_content {
    content      = base64encode(random_password.cluster_token.result)
    content_type = "BASE64"
  }

  timeouts {}
}
