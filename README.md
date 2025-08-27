# CATO 2 NIC VSOCKET Azure  VNET Terraform module

Terraform module which creates a VNET in Azure, required subnets, network interfaces, security groups, route tables, an Azure Socket Site in the Cato Management Application (CMA), optionally updates sockets bandwidth, add routed ranges with names and deploys a 2 nic primary.

You can also use an existing VNET and or Resource group following the instructions in the module.

## NOTE
- The current API that the Cato provider is calling requires sequential execution. 
Cato recommends setting the value to 1. Example call: terraform apply -parallelism=1.
- VM size is Standard D2s v5 (2 vcpus, 8 GiB memory) for more efficient cost management.
- This module will look up the Cato Site Location information based on the Location of Azure specified.  If you would like to override this behavior, please leverage the below for help finding the correct values.
- For help with finding exact sytax to match site location for city, state_name, country_name and timezone, please refer to the [cato_siteLocation data source](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/siteLocation).
- For help with finding a license id to assign, please refer to the [cato_licensingInfo data source](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/licensingInfo).
- For Translated Ranges, "Enable Static Range Translation" but be enabled for more information please refer to [Configuring System Settings for the Account](https://support.catonetworks.com/hc/en-us/articles/4413280536849-Configuring-System-Settings-for-the-Account)


## Usage

```hcl
provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {}
}

provider "cato" {
  baseurl    = var.baseurl
  token      = var.token
  account_id = var.account_id
}

variable "azure_subscription_id" {
  default = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
}

variable "baseurl" {}
variable "token" {}
variable "account_id" {}



module "vsocket-azure-vnet-2nic" {
  source                = "catonetworks/terraform-cato-vsocket-azure-vnet-2nic"
  token                 = var.token
  account_id            = var.account_id
  azure_subscription_id = var.azure_subscription_id
  baseurl               = var.baseurl
  location              = "West Europe"
  vnet_name             = "test-vnet" # Required for both creating or using existing VNET
  resource_group_name   = "test-rg"
  # ┌───── Optional Custom Naming for Azure Resources ─────┐
  resource_prefix_name        = null # Variable to prefix all resources
  vsocket_name                = null                           
  wan_subnet_name             = null                 
  lan_subnet_name             = null                 
  vsocket_disk_name           = null
  # └──────────────────────────────────────────────────────┘
  create_resource_group = true # Set to false if you want to deploy to existing Resource Group and provide current name to resource_group_name
  create_vnet           = true
  vnet_prefix           = "10.113.0.0/16"
  subnet_range_wan      = "10.113.2.0/24"
  subnet_range_lan      = "10.113.3.128/25"
  lan_ip                = "10.113.3.135"

   # ┌───── Optional Availability configuration ─────┐
  vsocket_zone           = "1"
  # You cannot use Zones and Availability sets
  availability_set_id    = null
  # └────────────────────────────────────────────────┘
   
  enable_static_range_translation = false #set to true if the Account settings has been updated.
  routed_networks = {
    "Peered-VNET-1" = {
      subnet = "10.100.1.0/24"
      # interface_index is omitted, so it will default to "LAN1".
    }
    "On-Prem-Network-With-NAT" = {
      subnet            = "192.168.51.0/24"
      translated_subnet = "10.250.3.0/24" # Example translated range, SRT Required, set 
      interface_index = "LAN2" # Overriding the default value.
      gateway = "192.168.51.254" # Overriding the default value of LAN1 LocalIP
    }
  }

  upstream_bandwidth   = 1000
  downstream_bandwidth = 1000
  site_name             = "Your Site name here"
  site_description      = "Your description here"
  # Site location is Derived from Azure Region Location
  tags = {
    example_key = "example_value"
    terraform = "true"
    git_repo = "https://github.com/catonetworks/terraform-cato-vsocket-azure-vnet-2nic"
  }
}
```

## Site Location Reference

For more information on site_location syntax, use the [Cato CLI](https://github.com/catonetworks/cato-cli) to lookup values.

```bash
$ pip3 install catocli
$ export CATO_TOKEN="your-api-token-here"
$ export CATO_ACCOUNT_ID="your-account-id"
$ catocli query siteLocation -h
$ catocli query siteLocation '{"filters":[{"search": "San Diego","field":"city","operation":"exact"}]}' -p
```

## Authors

Module is maintained by [Cato Networks](https://github.com/catonetworks) with help from [these awesome contributors](https://github.com/catonetworks/terraform-cato-vsocket-azure-vnet-2nic/graphs/contributors).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/catonetworks/terraform-cato-vsocket-azure-vnet-2nic/tree/master/LICENSE) for full details.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.33.0 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.38 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.33.0 |
| <a name="provider_cato"></a> [cato](#provider\_cato) | >= 0.0.38 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.availability-set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_linux_virtual_machine.vsocket](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.lan-nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.wan-nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.lan-sg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.wan-sg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.wan-public-ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.azure-rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_route.lan-route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route.public-rt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route.route-internet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route_table.private-rt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_route_table.public-rt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet.subnet-lan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.subnet-wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.lan-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.wan-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.rt-table-association-lan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.rt-table-association-wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_machine_extension.vsocket-custom-script](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_dns_servers.dns_servers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_dns_servers) | resource |
| [cato_license.license](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/license) | resource |
| [cato_network_range.routedAzure](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/network_range) | resource |
| [cato_socket_site.azure-site](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/socket_site) | resource |
| [cato_wan_interface.wan](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/wan_interface) | resource |
| [random_string.vsocket-random-password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.vsocket-random-username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.sleep_5_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sleep_before_delete](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_network_interface.lannicmac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wannicmac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_resource_group.data-azure-rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |
| [cato_accountSnapshotSite.azure-site](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/accountSnapshotSite) | data source |
| [cato_accountSnapshotSite.azure-site-2](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/accountSnapshotSite) | data source |
| [cato_siteLocation.site_location](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/siteLocation) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID used for the Cato Networks integration. | `number` | `null` | no |
| <a name="input_availability_set_id"></a> [availability\_set\_id](#input\_availability\_set\_id) | Availability set ID | `string` | `null` | no |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | The Azure Subscription ID where the resources will be created. Example: 00000000-0000-0000-0000-000000000000 | `string` | n/a | yes |
| <a name="input_baseurl"></a> [baseurl](#input\_baseurl) | Base URL for the Cato Networks API. | `string` | `"https://api.catonetworks.com/api/v1/graphql2"` | no |
| <a name="input_commands"></a> [commands](#input\_commands) | n/a | `list(string)` | <pre>[<br/>  "rm /cato/deviceid.txt",<br/>  "rm /cato/socket/configuration/socket_registration.json",<br/>  "nohup /cato/socket/run_socket_daemon.sh &"<br/>]</pre> | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Resource group creation true will create and false will use exsiting | `bool` | n/a | yes |
| <a name="input_create_vnet"></a> [create\_vnet](#input\_create\_vnet) | Whether or not to create the Vnet, or use existing Vnet | `bool` | `false` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | n/a | `list(string)` | <pre>[<br/>  "168.63.129.16",<br/>  "10.254.254.1",<br/>  "1.1.1.1",<br/>  "8.8.8.8"<br/>]</pre> | no |
| <a name="input_downstream_bandwidth"></a> [downstream\_bandwidth](#input\_downstream\_bandwidth) | Sockets downstream interface WAN Bandwidth in Mbps | `string` | `"null"` | no |
| <a name="input_enable_boot_diagnostics"></a> [enable\_boot\_diagnostics](#input\_enable\_boot\_diagnostics) | If true, enables boot diagnostics with a managed storage account. If false, disables it. | `bool` | `true` | no |
| <a name="input_enable_static_range_translation"></a> [enable\_static\_range\_translation](#input\_enable\_static\_range\_translation) | Enables the ability to use translated ranges | `string` | `false` | no |
| <a name="input_lan_ip"></a> [lan\_ip](#input\_lan\_ip) | Local IP Address of socket LAN interface | `string` | `null` | no |
| <a name="input_lan_subnet_name"></a> [lan\_subnet\_name](#input\_lan\_subnet\_name) | Optional override name for the LAN subnet | `string` | `null` | no |
| <a name="input_license_bw"></a> [license\_bw](#input\_license\_bw) | The license bandwidth number for the cato site, specifying bandwidth ONLY applies for pooled licenses.  For a standard site license that is not pooled, leave this value null. Must be a number greater than 0 and an increment of 10. | `string` | `null` | no |
| <a name="input_license_id"></a> [license\_id](#input\_license\_id) | The license ID for the Cato vSocket of license type CATO\_SITE, CATO\_SSE\_SITE, CATO\_PB, CATO\_PB\_SSE.  Example License ID value: 'abcde123-abcd-1234-abcd-abcde1234567'.  Note that licenses are for commercial accounts, and not supported for trial accounts. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `null` | no |
| <a name="input_native_network_range"></a> [native\_network\_range](#input\_native\_network\_range) | Cato Native Network Range for the Site | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name required if you want to deploy into existing Resource group | `string` | n/a | yes |
| <a name="input_resource_prefix_name"></a> [resource\_prefix\_name](#input\_resource\_prefix\_name) | Prefix used for Azure resource names. Must conform to Azure naming restrictions. | `string` | `null` | no |
| <a name="input_routed_networks"></a> [routed\_networks](#input\_routed\_networks) | A map of routed networks to be accessed behind the vSocket site.<br/>  - The key is the logical name for the network.<br/>  - The value is an object containing:<br/>    - "subnet" (string, required): The actual CIDR range of the network.<br/>    - "translated\_subnet" (string, optional): The NATed CIDR range if translation is used.<br/>  Example: <br/>  routed\_networks = {<br/>    "Peered-VNET-1" = {<br/>      subnet = "10.100.1.0/24"<br/>    }<br/>    "On-Prem-Network-NAT" = {<br/>      subnet            = "192.168.51.0/24"<br/>      translated\_subnet = "10.200.1.0/24"<br/>    }<br/>  } | <pre>map(object({<br/>    subnet            = string<br/>    translated_subnet = optional(string)<br/>    gateway           = optional(string)<br/>    interface_index   = optional(string, "LAN1")<br/>  }))</pre> | `{}` | no |
| <a name="input_site_description"></a> [site\_description](#input\_site\_description) | Description of the vsocket site | `string` | n/a | yes |
| <a name="input_site_location"></a> [site\_location](#input\_site\_location) | Site location which is used by the Cato Socket to connect to the closest Cato PoP. If not specified, the location will be derived from the Azure region dynamicaly. | <pre>object({<br/>    city         = string<br/>    country_code = string<br/>    state_code   = string<br/>    timezone     = string<br/>  })</pre> | <pre>{<br/>  "city": null,<br/>  "country_code": null,<br/>  "state_code": null,<br/>  "timezone": null<br/>}</pre> | no |
| <a name="input_site_name"></a> [site\_name](#input\_site\_name) | Name of the vsocket site | `string` | n/a | yes |
| <a name="input_site_type"></a> [site\_type](#input\_site\_type) | The type of the site | `string` | `"CLOUD_DC"` | no |
| <a name="input_subnet_range_lan"></a> [subnet\_range\_lan](#input\_subnet\_range\_lan) | Choose a range within the VPC to use as the Private/LAN subnet. This subnet will host the target LAN interface of the vSocket so resources in the VPC (or AWS Region) can route to the Cato Cloud.<br/>    The minimum subnet length to support High Availability is /29.<br/>    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X | `string` | `null` | no |
| <a name="input_subnet_range_wan"></a> [subnet\_range\_wan](#input\_subnet\_range\_wan) | Choose a range within the VPC to use as the Public/WAN subnet. This subnet will be used to access the public internet and securely tunnel to the Cato Cloud.<br/>    The minimum subnet length to support High Availability is /28.<br/>    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A Map of Strings to describe infrastructure | `map(string)` | `{}` | no |
| <a name="input_token"></a> [token](#input\_token) | API token used to authenticate with the Cato Networks API. | `string` | n/a | yes |
| <a name="input_upstream_bandwidth"></a> [upstream\_bandwidth](#input\_upstream\_bandwidth) | Sockets upstream interface WAN Bandwidth in Mbps | `string` | `"null"` | no |
| <a name="input_vm_image_config"></a> [vm\_image\_config](#input\_vm\_image\_config) | Configuration for the Marketplace image, including plan and source image reference. | <pre>object({<br/>    publisher = string<br/>    offer     = string<br/>    product   = string<br/>    sku       = string<br/>    version   = string<br/>  })</pre> | <pre>{<br/>  "offer": "cato_socket",<br/>  "product": "cato_socket",<br/>  "publisher": "catonetworks",<br/>  "sku": "public-cato-socket",<br/>  "version": "23.0.19605"<br/>}</pre> | no |
| <a name="input_vm_os_disk_config"></a> [vm\_os\_disk\_config](#input\_vm\_os\_disk\_config) | Configuration for the Virtual Machine's OS disk. | <pre>object({<br/>    name_suffix          = string<br/>    caching              = string<br/>    storage_account_type = string<br/>    disk_size_gb         = number<br/>  })</pre> | <pre>{<br/>  "caching": "ReadWrite",<br/>  "disk_size_gb": 8,<br/>  "name_suffix": "vSocket-disk",<br/>  "storage_account_type": "Standard_LRS"<br/>}</pre> | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | (Required) Specifies the size of the Virtual Machine. See Azure VM Naming Conventions: https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions | `string` | `"Standard_D2s_v5"` | no |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | VNET Name required if you want to deploy into existing VNET | `string` | n/a | yes |
| <a name="input_vnet_prefix"></a> [vnet\_prefix](#input\_vnet\_prefix) | Choose a unique range for your new VPC that does not conflict with the rest of your Wide Area Network.<br/>    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X | `string` | `null` | no |
| <a name="input_vsocket_disk_name"></a> [vsocket\_disk\_name](#input\_vsocket\_disk\_name) | Optional override name for the vSocket Disk | `string` | `null` | no |
| <a name="input_vsocket_name"></a> [vsocket\_name](#input\_vsocket\_name) | Optional override name for the vSocket | `string` | `null` | no |
| <a name="input_vsocket_zone"></a> [vsocket\_zone](#input\_vsocket\_zone) | vsocket Availability Zone | `string` | `null` | no |
| <a name="input_wan_subnet_name"></a> [wan\_subnet\_name](#input\_wan\_subnet\_name) | Optional override name for the WAN subnet | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cato_license_site"></a> [cato\_license\_site](#output\_cato\_license\_site) | n/a |
| <a name="output_cato_site_id"></a> [cato\_site\_id](#output\_cato\_site\_id) | ID of the Cato Socket Site |
| <a name="output_cato_site_name"></a> [cato\_site\_name](#output\_cato\_site\_name) | Name of the Cato Site |
| <a name="output_cato_vsocket_serial"></a> [cato\_vsocket\_serial](#output\_cato\_vsocket\_serial) | Cato Socket Serial Number |
| <a name="output_lan_nic_id"></a> [lan\_nic\_id](#output\_lan\_nic\_id) | ID of the LAN Network Interface |
| <a name="output_lan_nic_mac_address"></a> [lan\_nic\_mac\_address](#output\_lan\_nic\_mac\_address) | MAC of the LAN Network Interface |
| <a name="output_lan_nic_name"></a> [lan\_nic\_name](#output\_lan\_nic\_name) | The name of the LAN network interface. |
| <a name="output_lan_subnet_id"></a> [lan\_subnet\_id](#output\_lan\_subnet\_id) | The ID of the LAN subnet within the virtual network. |
| <a name="output_lan_subnet_name"></a> [lan\_subnet\_name](#output\_lan\_subnet\_name) | The name of the LAN subnet within the virtual network. |
| <a name="output_site_location"></a> [site\_location](#output\_site\_location) | n/a |
| <a name="output_vsocket_vm_id"></a> [vsocket\_vm\_id](#output\_vsocket\_vm\_id) | ID of the vSocket Virtual Machine |
| <a name="output_vsocket_vm_name"></a> [vsocket\_vm\_name](#output\_vsocket\_vm\_name) | Name of the vSocket Virtual Machine |
| <a name="output_wan_nic_id"></a> [wan\_nic\_id](#output\_wan\_nic\_id) | ID of the WAN Network Interface |
| <a name="output_wan_nic_mac_address"></a> [wan\_nic\_mac\_address](#output\_wan\_nic\_mac\_address) | MAC of the WAN Network Interface |
| <a name="output_wan_nic_name"></a> [wan\_nic\_name](#output\_wan\_nic\_name) | The name of the WAN network interface. |
<!-- END_TF_DOCS -->