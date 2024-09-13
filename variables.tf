variable "location" {
  type        = string
  description = "Azure region for the resources"
  default     = "UK South"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "databricks_workspace_name" {
  type        = string
  description = "Name of Databricks workspace"
}

variable "account_id" {
  type        = string
  description = "account id of the databricks account"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The address space for the VNet"
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "prefix" {
  type        = string
  description = "Prefix used for the resources"
}