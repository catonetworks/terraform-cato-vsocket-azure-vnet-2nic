## The following attributes are exported:
output "wan_nic_name" {
  description = "The name of the WAN network interface."
  value       = azurerm_network_interface.wan-nic.name
}

output "lan_nic_name" {
  description = "The name of the LAN network interface."
  value       = azurerm_network_interface.lan-nic.name
}
output "lan_subnet_id" {
  description = "The ID of the LAN subnet within the virtual network."
  value       = azurerm_subnet.subnet-lan.id
}

output "lan_subnet_name" {
  description = "The name of the LAN subnet within the virtual network."
  value       = azurerm_subnet.subnet-lan.name
}

# Cato Socket Site Outputs
output "cato_site_id" {
  description = "ID of the Cato Socket Site"
  value       = cato_socket_site.azure-site.id
}

output "cato_site_name" {
  description = "Name of the Cato Site"
  value       = cato_socket_site.azure-site.name
}

output "cato_vsocket_serial" {
  description = "Cato Socket Serial Number"
  value       = try(local.vsocket_serial[0], "N/A")
}

# Network Interfaces Outputs
output "wan_nic_id" {
  description = "ID of the WAN Network Interface"
  value       = azurerm_network_interface.wan-nic.id
}

output "lan_nic_id" {
  description = "ID of the LAN Network Interface"
  value       = azurerm_network_interface.lan-nic.id
}

output "lan_nic_mac_address" {
  description = "MAC of the LAN Network Interface"
  value       = azurerm_network_interface.lan-nic
}

output "wan_nic_mac_address" {
  description = "MAC of the WAN Network Interface"
  value       = azurerm_network_interface.wan-nic
}

# Virtual Machine Outputs
output "vsocket_vm_id" {
  description = "ID of the vSocket Virtual Machine"
  value       = azurerm_linux_virtual_machine.vsocket.id
}

output "vsocket_vm_name" {
  description = "Name of the vSocket Virtual Machine"
  value       = azurerm_linux_virtual_machine.vsocket.name
}

output "cato_license_site" {
  value = var.license_id == null ? null : {
    id           = cato_license.license[0].id
    license_id   = cato_license.license[0].license_id
    license_info = cato_license.license[0].license_info
    site_id      = cato_license.license[0].site_id
  }
}
