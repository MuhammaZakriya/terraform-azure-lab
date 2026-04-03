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
  description = "Admin password for VM "
  default     = "P@ssw0rd123456!"
  sensitive   = true
}
variable "role_principal_id" {
  description = "Principal ID for role assignment"
  default     = "0538bbf6-cc90-4d7e-800d-353c47b49725"
}
