variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "cidr_blocks" {
  description = "CIDRs of the network, use index 0 for everything"
  type        = list(any)
}

variable "ssh_management_network" {
  description = "Subnet allowed to ssh to hosts"
  type        = string
}