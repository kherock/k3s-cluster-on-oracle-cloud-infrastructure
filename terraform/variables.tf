variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "ampere_ad_number" {
  description = "Availabiliby Domain number for Ampere instances"
  type        = number
}

variable "cloudflare_api_token" {
  description = "API token used to access basic Cloudflare APIs"
  type        = string
  default     = null
}

variable "region" {
  description = "The region to connect to."
  type        = string
  default     = null
}

variable "ssh_authorized_keys" {
  description = "List of authorized SSH keys"
  type        = list(string)
  default     = []
}
