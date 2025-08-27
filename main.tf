resource "random_string" "vsocket-random-username" {
  length  = 16
  special = false
}

resource "random_string" "vsocket-random-password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}
## VNET Module Resources
resource "azurerm_resource_group" "azure-rg" {
  count    = var.create_resource_group ? 1 : 0
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

resource "azurerm_availability_set" "availability-set" {
  location                     = var.location
  name                         = "${local.resource_name_prefix}-availabilitySet"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  resource_group_name          = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

## Create Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  count         = var.create_vnet ? 1 : 0
  address_space = [var.vnet_prefix]
  location      = var.location
  name          = var.vnet_name == null ? "${local.resource_name_prefix}-vnet" : var.vnet_name

  resource_group_name = local.resource_group_name
  depends_on = [
    data.azurerm_resource_group.data-azure-rg
  ]
  tags = var.tags
}

resource "azurerm_virtual_network_dns_servers" "dns_servers" {
  virtual_network_id = local.vnet_id
  dns_servers        = var.dns_servers
}

resource "azurerm_subnet" "subnet-wan" {
  address_prefixes     = [var.subnet_range_wan]
  name                 = local.wan_subnet_name_local
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.vnet_name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-lan" {
  address_prefixes     = [var.subnet_range_lan]
  name                 = local.lan_subnet_name_local
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.vnet_name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "wan-public-ip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "${local.resource_name_prefix}-wanPublicIP"
  resource_group_name = local.resource_group_name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

# Create Network Interfaces
resource "azurerm_network_interface" "wan-nic" {
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  location                       = var.location
  name                           = "${local.resource_name_prefix}-wan"
  resource_group_name            = local.resource_group_name
  ip_configuration {
    name                          = "${local.resource_name_prefix}-wanIP"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip.id
    subnet_id                     = azurerm_subnet.subnet-wan.id
  }
  depends_on = [
    azurerm_public_ip.wan-public-ip,
    azurerm_subnet.subnet-wan
  ]
  tags = var.tags
}


resource "azurerm_network_interface" "lan-nic" {
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  location                       = var.location
  name                           = "${local.resource_name_prefix}-lan"
  resource_group_name            = local.resource_group_name
  ip_configuration {
    name                          = "${local.resource_name_prefix}-lanIPConfig"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_ip
    subnet_id                     = azurerm_subnet.subnet-lan.id
  }
  depends_on = [
    azurerm_subnet.subnet-lan
  ]
  lifecycle {
    ignore_changes = [ip_configuration] #Ignoring Changes because the Floating IP will move based on Active Device
  }
  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "wan-association" {
  subnet_id                 = azurerm_subnet.subnet-wan.id
  network_security_group_id = azurerm_network_security_group.wan-sg.id
}

resource "azurerm_subnet_network_security_group_association" "lan-association" {
  subnet_id                 = azurerm_subnet.subnet-lan.id
  network_security_group_id = azurerm_network_security_group.lan-sg.id
}

# Create Security Groups
resource "azurerm_network_security_group" "wan-sg" {
  location            = var.location
  name                = "${local.resource_name_prefix}-WANSecurityGroup"
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "Allow-DNS-TCP"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Allow-DNS-UDP"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Allow-HTTPS-TCP"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Allow-HTTPS-UDP"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Deny-All-Outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_network_security_group" "lan-sg" {
  location            = var.location
  name                = "${local.resource_name_prefix}-LANSecurityGroup"
  resource_group_name = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

# Create Route Tables, Routes and Associations 
resource "azurerm_route_table" "private-rt" {
  bgp_route_propagation_enabled = false
  location                      = var.location
  name                          = "${local.resource_name_prefix}-viaCato"
  resource_group_name           = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_route" "public-rt" {
  address_prefix      = "23.102.135.246/32" #
  name                = "Microsoft-KMS"
  next_hop_type       = "Internet"
  resource_group_name = local.resource_group_name
  route_table_name    = "${local.resource_name_prefix}-viaCato"
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route" "lan-route" {
  address_prefix         = "0.0.0.0/0"
  name                   = "default-cato"
  next_hop_in_ip_address = var.lan_ip
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = local.resource_group_name
  route_table_name       = "${local.resource_name_prefix}-viaCato"
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route_table" "public-rt" {
  bgp_route_propagation_enabled = false
  location                      = var.location
  name                          = "${local.resource_name_prefix}-viaInternet"
  resource_group_name           = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_route" "route-internet" {
  address_prefix      = "0.0.0.0/0"
  name                = "default-internet"
  next_hop_type       = "Internet"
  resource_group_name = local.resource_group_name
  route_table_name    = "${local.resource_name_prefix}-viaInternet"
  depends_on = [
    azurerm_route_table.public-rt
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-wan" {
  route_table_id = azurerm_route_table.public-rt.id
  subnet_id      = azurerm_subnet.subnet-wan.id
  depends_on = [
    azurerm_route_table.public-rt,
    azurerm_subnet.subnet-wan,
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-lan" {
  route_table_id = azurerm_route_table.private-rt.id
  subnet_id      = azurerm_subnet.subnet-lan.id
  depends_on = [
    azurerm_route_table.private-rt,
    azurerm_subnet.subnet-lan
  ]
}

resource "cato_socket_site" "azure-site" {
  connection_type = "SOCKET_AZ1500"
  description     = var.site_description
  name            = var.site_name
  native_range = {
    native_network_range = var.native_network_range == null ? var.subnet_range_lan : var.native_network_range
    local_ip             = azurerm_network_interface.lan-nic.private_ip_address
  }
  site_location = local.cur_site_location
  site_type     = var.site_type
}


# Create Primary Vsocket Virtual Machine
resource "azurerm_linux_virtual_machine" "vsocket" {
  location              = var.location
  name                  = local.vsocket_name_local
  computer_name         = local.vsocket_name_local
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.wan-nic.id, azurerm_network_interface.lan-nic.id]
  resource_group_name   = local.resource_group_name

  availability_set_id = var.availability_set_id
  zone                = var.vsocket_zone

  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true

  admin_username = random_string.vsocket-random-username.result
  admin_password = "${random_string.vsocket-random-password.result}@"

  # OS disk configuration from variables
  os_disk {
    name                 = local.vsocket_disk_name_local
    caching              = var.vm_os_disk_config.caching
    storage_account_type = var.vm_os_disk_config.storage_account_type
    disk_size_gb         = var.vm_os_disk_config.disk_size_gb
  }

  # Boot diagnostics controlled by a boolean variable
  boot_diagnostics {
    # An empty string enables managed boot diagnostics. `null` disables the block.
    storage_account_uri = var.enable_boot_diagnostics ? "" : null
  }

  # Plan information from the image configuration variable
  plan {
    name      = var.vm_image_config.sku
    publisher = var.vm_image_config.publisher
    product   = var.vm_image_config.product
  }

  # Source image reference from the image configuration variable
  source_image_reference {
    publisher = var.vm_image_config.publisher
    offer     = var.vm_image_config.offer
    sku       = var.vm_image_config.sku
    version   = var.vm_image_config.version
  }


  depends_on = [
    cato_socket_site.azure-site,
    data.cato_accountSnapshotSite.azure-site,
    data.cato_accountSnapshotSite.azure-site-2
  ]
  tags = var.tags
}


# To allow mac address to be retrieved
resource "time_sleep" "sleep_5_seconds" {
  create_duration = "5s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket]
}

data "azurerm_network_interface" "wannicmac" {
  name                = "${local.resource_name_prefix}-wan"
  resource_group_name = local.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

data "azurerm_network_interface" "lannicmac" {
  name                = "${local.resource_name_prefix}-lan"
  resource_group_name = local.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

variable "commands" {
  type = list(string)
  default = [
    "rm /cato/deviceid.txt",
    "rm /cato/socket/configuration/socket_registration.json",
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

resource "azurerm_virtual_machine_extension" "vsocket-custom-script" {
  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
{
  "commandToExecute": "echo '${local.vsocket_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${azurerm_network_interface.wan-nic.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${azurerm_network_interface.wan-nic.private_ip_address}\",\"lan_nic\":\"${azurerm_network_interface.lan-nic.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${azurerm_network_interface.lan-nic.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
}
SETTINGS

  depends_on = [
    azurerm_linux_virtual_machine.vsocket,
    data.azurerm_network_interface.lannicmac,
    data.azurerm_network_interface.wannicmac
  ]
  tags = var.tags
}

# Allow vSocket to be disconnected to delete site
resource "time_sleep" "sleep_before_delete" {
  destroy_duration = "30s"
}

resource "cato_network_range" "routedAzure" {
  for_each        = var.routed_networks
  site_id         = cato_socket_site.azure-site.id
  name            = each.key
  range_type      = "Routed"
  gateway         = coalesce(each.value.gateway, local.lan_first_ip)
  interface_index = each.value.interface_index
  # Access attributes from the value object
  subnet            = each.value.subnet
  translated_subnet = var.enable_static_range_translation ? coalesce(each.value.translated_subnet, each.value.subnet) : null
  # This will be null if not defined, and the provider will ignore it.
}

# Update socket Bandwidth
resource "cato_wan_interface" "wan" {
  site_id              = cato_socket_site.azure-site.id
  interface_id         = "WAN1"
  name                 = "WAN 1"
  upstream_bandwidth   = var.upstream_bandwidth
  downstream_bandwidth = var.downstream_bandwidth
  role                 = "wan_1"
  precedence           = "ACTIVE"
}

# Cato license resource
resource "cato_license" "license" {
  count      = var.license_id == null ? 0 : 1
  site_id    = cato_socket_site.azure-site.id
  license_id = var.license_id
  bw         = var.license_bw == null ? null : var.license_bw
}
