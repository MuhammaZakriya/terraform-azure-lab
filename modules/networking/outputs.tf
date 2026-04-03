output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "public_subnet_id" { value = azurerm_subnet.public.id }
output "private_subnet_id" { value = azurerm_subnet.private.id }
output "public_nic_id" { value = azurerm_network_interface.public_nic.id }
output "private_nic_id" { value = azurerm_network_interface.private_nic.id }
output "public_ip_address" { value = azurerm_public_ip.public_ip.ip_address }
