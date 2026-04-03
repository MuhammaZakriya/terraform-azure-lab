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
