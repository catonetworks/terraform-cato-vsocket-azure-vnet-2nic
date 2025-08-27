locals {
  vsocket_serial          = [for s in data.cato_accountSnapshotSite.azure-site.info.sockets : s.serial if s.is_primary == true]
  lan_first_ip            = cidrhost(var.subnet_range_lan, 1)
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.azure-rg[0].name : var.resource_group_name
  vnet_name               = var.create_vnet ? azurerm_virtual_network.vnet[0].name : var.vnet_name
  vnet_id                 = var.create_vnet ? azurerm_virtual_network.vnet[0].id : data.azurerm_virtual_network.this[0].id
  vsocket_name_local      = var.vsocket_name != null ? var.vsocket_name : "Cato-vSocket"
  wan_subnet_name_local   = var.wan_subnet_name != null ? var.wan_subnet_name : "${local.resource_name_prefix}-subnetWAN"
  lan_subnet_name_local   = var.lan_subnet_name != null ? var.lan_subnet_name : "${local.resource_name_prefix}-subnetLAN"
  vsocket_disk_name_local = var.vsocket_disk_name != null ? var.vsocket_disk_name : "${local.resource_name_prefix}-vSocket-disk"
  resource_name_prefix    = var.resource_prefix_name == null ? var.site_name : var.resource_prefix_name
}
