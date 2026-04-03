output "public_vm_id" { value = azurerm_virtual_machine.public_vm.id }
output "private_vm_id" { value = azurerm_linux_virtual_machine.private_vm.id }