terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatezakriya2026"
    container_name       = "terraform-state"
    key                  = "complete-lab-rg.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_nic_id       = module.networking.public_nic_id
  private_nic_id      = module.networking.private_nic_id
  computer_name       = var.computer_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}

module "iam" {
  source = "./modules/iam"

  resource_group_name = azurerm_resource_group.rg.name
  principal_id        = var.role_principal_id
}
