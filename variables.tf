variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "complete-lab-rg"
}

variable "location" {
  description = "Azure region"
  default     = "centralindia"
}

variable "computer_name" {
  description = "Computer name for VM"
  default     = "myvm"
}

variable "admin_username" {
  description = "Admin username for VM"
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VM (must be complex)"
  default     = "P@ssw0rd123456!"
  sensitive   = true
}