
output "vault_id" {
  description = "KMS Vault ID for storing cluster secrets"
  value       = oci_kms_vault.cluster.id
}

output "master_key_id" {
  description = "KMS Vault master key ID for storing cluster secrets"
  value       = oci_kms_key.master.id
}
