
## Cato Provider Variables
variable "site_name" {
  description = "Name of the vsocket site"
  type        = string
}

variable "site_description" {
  description = "Description of the vsocket site"
  type        = string
}

variable "site_type" {
  description = "The type of the site"
  type        = string
  default     = "CLOUD_DC"
  validation {
    condition     = contains(["DATACENTER", "BRANCH", "CLOUD_DC", "HEADQUARTERS"], var.site_type)
    error_message = "The site_type variable must be one of 'DATACENTER','BRANCH','CLOUD_DC','HEADQUARTERS'."
  }
}

variable "site_location" {
  description = "Site location which is used by the Cato Socket to connect to the closest Cato PoP. If not specified, the location will be derived from the Azure region dynamicaly."
  type = object({
    city         = string
    country_code = string
    state_code   = string
    timezone     = string
  })
  default = {
    city         = null
    country_code = null
    state_code   = null ## Optional - for countries with states
    timezone     = null
  }
}


## VNET Variables
variable "create_resource_group" {
  description = "Resource group creation true will create and false will use exsiting"
  type        = bool
}

variable "resource_group_name" {
  description = "Resource group name required if you want to deploy into existing Resource group"
  type        = string
}

variable "resource_prefix_name" {
  description = "Prefix used for Azure resource names. Must conform to Azure naming restrictions."
  type        = string
  default     = null

  validation {
    condition = (
      # Allow null values to pass validation
      var.resource_prefix_name == null || (
        # Not starting with underscore
        can(regex("^[^_]", var.resource_prefix_name)) &&
        # Not ending with dot or hyphen
        can(regex("[^.-]$", var.resource_prefix_name)) &&
        # Allowed characters only: a-zA-Z0-9 . _ -
        can(regex("^[a-zA-Z0-9._-]+$", var.resource_prefix_name)) &&
        # No forbidden special characters or whitespace
        !can(regex("[\\s\\\\/\"\\[\\]:|<>+=;,\\?*@&#%]", var.resource_prefix_name))
      )
    )
    error_message = <<EOT
Invalid resource_prefix_name.

The value must:
- Not begin with an underscore (_)
- Not end with a hyphen (-) or period (.)
- Only include letters, digits, hyphens (-), underscores (_), and periods (.)
- Not contain any of the following: \ / " [ ] : | < > + = ; , ? * @ & # % or whitespace

Example of a valid name: "app_prefix-01.cato"
EOT
  }
}
variable "vnet_name" {
  description = "VNET Name required if you want to deploy into existing VNET"
  type        = string
}

variable "location" {
  type    = string
  default = null
}

variable "lan_ip" {
  type        = string
  description = "Local IP Address of socket LAN interface"
  default     = null
}

variable "dns_servers" {
  type = list(string)
  default = [
    "168.63.129.16", # Azure DNS
    "10.254.254.1",  # Cato Cloud DNS
    "1.1.1.1",
    "8.8.8.8"
  ]
}

variable "subnet_range_wan" {
  type        = string
  description = <<EOT
    Choose a range within the VPC to use as the Public/WAN subnet. This subnet will be used to access the public internet and securely tunnel to the Cato Cloud.
    The minimum subnet length to support High Availability is /28.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "subnet_range_lan" {
  type        = string
  description = <<EOT
    Choose a range within the VPC to use as the Private/LAN subnet. This subnet will host the target LAN interface of the vSocket so resources in the VPC (or AWS Region) can route to the Cato Cloud.
    The minimum subnet length to support High Availability is /29.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}


variable "vnet_prefix" {
  type        = string
  description = <<EOT
  	Choose a unique range for your new VPC that does not conflict with the rest of your Wide Area Network.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "routed_networks" {
  description = <<EOF
  A map of routed networks to be accessed behind the vSocket site.
  - The key is the logical name for the network.
  - The value is an object containing:
    - "subnet" (string, required): The actual CIDR range of the network.
    - "translated_subnet" (string, optional): The NATed CIDR range if translation is used.
  Example: 
  routed_networks = {
    "Peered-VNET-1" = {
      subnet = "10.100.1.0/24"
    }
    "On-Prem-Network-NAT" = {
      subnet            = "192.168.51.0/24"
      translated_subnet = "10.200.1.0/24"
    }
  }
  EOF
  type = map(object({
    subnet            = string
    translated_subnet = optional(string)
    gateway           = optional(string)
    interface_index   = optional(string, "LAN1")
  }))
  default = {}
}

variable "vm_size" {
  description = "(Required) Specifies the size of the Virtual Machine. See Azure VM Naming Conventions: https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions"
  type        = string
  default     = "Standard_D2s_v5"
}

## Socket interface settings
variable "upstream_bandwidth" {
  description = "Sockets upstream interface WAN Bandwidth in Mbps"
  type        = string
  default     = "null"
}

variable "downstream_bandwidth" {
  description = "Sockets downstream interface WAN Bandwidth in Mbps"
  type        = string
  default     = "null"
}

# Avalability Zones and sets
variable "availability_set_id" {
  description = "Availability set ID"
  type        = string
  default     = null
}

variable "license_id" {
  description = "The license ID for the Cato vSocket of license type CATO_SITE, CATO_SSE_SITE, CATO_PB, CATO_PB_SSE.  Example License ID value: 'abcde123-abcd-1234-abcd-abcde1234567'.  Note that licenses are for commercial accounts, and not supported for trial accounts."
  type        = string
  default     = null
}

variable "license_bw" {
  description = "The license bandwidth number for the cato site, specifying bandwidth ONLY applies for pooled licenses.  For a standard site license that is not pooled, leave this value null. Must be a number greater than 0 and an increment of 10."
  type        = string
  default     = null
}

variable "create_vnet" {
  description = "Whether or not to create the Vnet, or use existing Vnet"
  type        = bool
  default     = false
}

variable "native_network_range" {
  description = "Cato Native Network Range for the Site"
  type        = string
  default     = null
}

variable "vm_os_disk_config" {
  description = "Configuration for the Virtual Machine's OS disk."
  type = object({
    name_suffix          = string
    caching              = string
    storage_account_type = string
    disk_size_gb         = number
  })
  default = {
    name_suffix          = "vSocket-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 8
  }
}

variable "vm_image_config" {
  description = "Configuration for the Marketplace image, including plan and source image reference."
  type = object({
    publisher = string
    offer     = string
    product   = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "catonetworks"
    offer     = "cato_socket"
    product   = "cato_socket"
    sku       = "public-cato-socket"
    version   = "23.0.19605"
  }
}

variable "enable_boot_diagnostics" {
  description = "If true, enables boot diagnostics with a managed storage account. If false, disables it."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A Map of Strings to describe infrastructure"
  type        = map(string)
  default     = {}
}

variable "vsocket_zone" {
  description = "vsocket Availability Zone"
  type        = string
  default     = null
}

variable "vsocket_name" {
  description = "Optional override name for the vSocket"
  type        = string
  default     = null
}

variable "wan_subnet_name" {
  description = "Optional override name for the WAN subnet"
  type        = string
  default     = null
}

variable "lan_subnet_name" {
  description = "Optional override name for the LAN subnet"
  type        = string
  default     = null
}

variable "vsocket_disk_name" {
  description = "Optional override name for the vSocket Disk"
  type        = string
  default     = null
}

variable "enable_static_range_translation" {
  description = "Enables the ability to use translated ranges"
  type        = string
  default     = false
}