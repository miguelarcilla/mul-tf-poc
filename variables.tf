##############################################################################
# Variables File
# 
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)
 
variable "subscription_id" {
  description = "The ID of your Azure Subscripion."
  default     = "null"
}

variable "location" {
  description = "The default region where the virtual network and app resources are created."
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "The name of your Azure Resource Group."
  default     = "mul-rg"
}

variable "virtual_network_name" {
  description = "The name for your virtual network."
  default     = "mul-vnet"
}

variable "virtual_network_address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = ["192.168.0.0/24"]
}

variable "bastion_subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "192.168.0.0/27"
}

variable "gateway_subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "192.168.0.32/28"
}

variable "public_subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "192.168.0.48/28"
}

variable "jumpbox_subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "192.168.0.64/28"
}

variable "web_subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "192.168.0.80/28"
}

variable "database_subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "192.168.0.96/28"
}

variable "admin_username" {
  description = "Administrator user name."
  default     = "adminuser"
}

variable "ssh_public_key" {
  description = "Default SSH key for new VMs."
  default     = "null"
}

variable "azure_container_registry_name" {
  description = "The name for your private Container Registry."
  default     = "mulacr"
}

variable "bastion_name" {
  description = "The name and prefix for Azure Bastion resources."
  default     = "mul-bastion"
}

variable "jumpbox_name" {
  description = "The name and prefix for Jumpbox resources."
  default     = "mul-jump"
}

variable "web_name" {
  description = "The name and prefix for web server resources."
  default     = "mul-web"
}

variable "app_name" {
  description = "The name and prefix for public application resources."
  default     = "mul-app"
}

variable "db_name" {
  description = "The name and prefix for application database resource."
  default     = "mul-db"
}

