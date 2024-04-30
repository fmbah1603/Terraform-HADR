variable "location" {
  description = "Location"
  type        = list(string)
  default     = ["usgovvirginia", "usgovarizona"]
}

variable "Linux_bastion" {
  description = "Whether Linux Bastion should be created as part of apply"
  type        = bool
  default     = false
}

variable "Windows_bastion" {
  description = "Whether Windows Bastion should be created as part of apply"
  type        = bool
  default     = false
}

variable "virtual_machine_name" {
  description = "Name of Bastion host"
  type        = list(string)
  default     = ["hadrvm0001", "hadrvm0002"]
}

variable "virtual_machine_username" {
  description = "Username of Bastion host"
  default     = "hadr"
}

variable "virtual_machine_password" {
  description = "Password of Bastion host"
  default     = "ligHTBEam@123"
}

variable "resource_group_name" {
  description = "HADR"
  type        = list(string)
  default     = ["az-ha-dev-usva-rg", "az-ha-dev-usaz-rg", "az-opa-dev-usva-rg", "az-opa-dev-usaz-rg"]
}

variable "virtual_network_name" {
  description = "HADR"
  type        = list(string)
  default     = ["az-opa-dev-usva-vnet", "az-opa-dev-usaz-vnet"]
}

variable "subnet_name" {
  description = "HADR"
  type        = string
  default     = "AppSubnet"
}

variable "subscription_id" {
  description = "Subscription id for the statefile storage account"
  type        = string
  default     = "91da15f8-3ba9-4916-afe1-da3b8651e6d5"
}