# convert-to-modules.ps1 (Fixed Version)
# Run this script in your Terraform project directory

Write-Host "Starting Terraform module conversion..." -ForegroundColor Cyan

# 1. Check if required files exist
$requiredFiles = @("main.tf", "variables.tf", "outputs.tf")
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "ERROR: $file not found in current directory!" -ForegroundColor Red
        exit 1
    }
}

# 2. Backup original files
Write-Host "Backing up original files..." -ForegroundColor Yellow
Copy-Item main.tf main.tf.bak -Force
Copy-Item variables.tf variables.tf.bak -Force
Copy-Item outputs.tf outputs.tf.bak -Force

# 3. Create module directories
Write-Host "Creating module directories..." -ForegroundColor Yellow
$moduleDirs = @(
    "modules/networking",
    "modules/compute",
    "modules/iam"
)
foreach ($dir in $moduleDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# 4. Create networking module (REMOVED unused variables)
Write-Host "Creating networking module..." -ForegroundColor Yellow

# modules/networking/variables.tf (only what's needed)
@'
variable "resource_group_name" {}
variable "location" {}
'@ | Out-File -FilePath modules/networking/variables.tf -Encoding utf8

# modules/networking/main.tf (same as before, but removed unused var references)
$networkingMain = @'
# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

# Public Subnet
resource "azurerm_subnet" "public" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet
resource "azurerm_subnet" "private" {
  name                 = "${var.resource_group_name}-subnet1"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP for VM
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.resource_group_name}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public NIC
resource "azurerm_network_interface" "public_nic" {
  name                = "${var.resource_group_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Private NIC
resource "azurerm_network_interface" "private_nic" {
  name                = "${var.resource_group_name}-private-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.resource_group_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FRONTEND"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5173"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "BACKEND"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Route table for public subnet
resource "azurerm_route_table" "public_rt" {
  name                = "${var.resource_group_name}-public-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name           = "to-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "public_rt_assoc" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public_rt.id
}

# NAT Gateway
resource "azurerm_public_ip" "nat_ip" {
  name                = "${var.resource_group_name}-nat-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${var.resource_group_name}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "private_nat" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}
'@
$networkingMain | Out-File -FilePath modules/networking/main.tf -Encoding utf8

# modules/networking/outputs.tf
@'
output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "public_subnet_id" { value = azurerm_subnet.public.id }
output "private_subnet_id" { value = azurerm_subnet.private.id }
output "public_nic_id" { value = azurerm_network_interface.public_nic.id }
output "private_nic_id" { value = azurerm_network_interface.private_nic.id }
output "public_ip_address" { value = azurerm_public_ip.public_ip.ip_address }
'@ | Out-File -FilePath modules/networking/outputs.tf -Encoding utf8

# 5. Create compute module (REMOVED unused computer_name)
Write-Host "Creating compute module..." -ForegroundColor Yellow

# modules/compute/variables.tf (removed computer_name)
@'
variable "resource_group_name" {}
variable "location" {}
variable "public_nic_id" {}
variable "private_nic_id" {}
variable "admin_username" {}
variable "admin_password" {}
'@ | Out-File -FilePath modules/compute/variables.tf -Encoding utf8

# modules/compute/main.tf (removed computer_name reference)
$computeMain = @'
# Public VM
resource "azurerm_linux_virtual_machine" "public_vm" {
  name                  = "${var.resource_group_name}-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [var.public_nic_id]
  size                  = "Standard_B2ps_v2"

  admin_username = var.admin_username
  admin_password = var.admin_password
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }
}

# Private VM
resource "azurerm_linux_virtual_machine" "private_vm" {
  name                  = "${var.resource_group_name}-private-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [var.private_nic_id]
  size                  = "Standard_B2ps_v2"

  admin_username = var.admin_username
  admin_password = var.admin_password
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }
}
'@
$computeMain | Out-File -FilePath modules/compute/main.tf -Encoding utf8

# modules/compute/outputs.tf
@'
output "public_vm_id" { value = azurerm_linux_virtual_machine.public_vm.id }
output "private_vm_id" { value = azurerm_linux_virtual_machine.private_vm.id }
'@ | Out-File -FilePath modules/compute/outputs.tf -Encoding utf8

# 6. Create IAM module (FIXED: principal_id as variable)
Write-Host "Creating IAM module..." -ForegroundColor Yellow

# modules/iam/variables.tf
@'
variable "resource_group_name" {}
variable "principal_id" {}
'@ | Out-File -FilePath modules/iam/variables.tf -Encoding utf8

# modules/iam/main.tf
$iamMain = @'
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
}
'@
$iamMain | Out-File -FilePath modules/iam/main.tf -Encoding utf8

# modules/iam/outputs.tf
@'
output "role_assignment_scope" { value = azurerm_role_assignment.contributor.scope }
'@ | Out-File -FilePath modules/iam/outputs.tf -Encoding utf8

# 7. Create new root main.tf (REMOVED unused variables)
Write-Host "Creating new root main.tf..." -ForegroundColor Yellow

$rootMain = @'
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
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}

module "iam" {
  source = "./modules/iam"

  resource_group_name = azurerm_resource_group.rg.name
  principal_id        = var.role_principal_id
}
'@
$rootMain | Out-File -FilePath main.tf -Encoding utf8

# 8. Add missing variable to root variables.tf
Write-Host "Adding role_principal_id variable to root variables.tf..." -ForegroundColor Yellow

# Check if role_principal_id already exists
$varContent = Get-Content variables.tf -Raw
if ($varContent -notmatch "role_principal_id") {
    Add-Content -Path variables.tf -Value @'

variable "role_principal_id" {
  description = "Principal ID for role assignment"
  default     = "0538bbf6-cc90-4d7e-800d-353c47b49725"
}
'@
}

# 9. Update root outputs.tf
Write-Host "Updating root outputs.tf..." -ForegroundColor Yellow

$rootOutputs = @'
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = module.networking.vnet_id
}

output "subnet_name" {
  value = module.networking.public_subnet_id
}

output "public_ip_address" {
  value = module.networking.public_ip_address
}

output "vm_name" {
  value = module.compute.public_vm_id
}

output "role_assignment_scope" {
  value = module.iam.role_assignment_scope
}
'@
$rootOutputs | Out-File -FilePath outputs.tf -Encoding utf8

Write-Host "Module conversion completed!" -ForegroundColor Green
Write-Host "Now run 'terraform plan' to verify no changes." -ForegroundColor Cyan