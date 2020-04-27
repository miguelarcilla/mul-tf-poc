##############################################################################
# This Terraform configuration will create the following:
#
# Resource group with a virtual network and standard subnets
# An Ubuntu Linux server running Apache

##############################################################################
# * Shared infrastructure resources

# Configure the Azure Provider
provider "azurerm" {
  version = "=2.0.0"
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  address_space       = var.virtual_network_address_space
  resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.group.name
  address_prefix       = var.bastion_subnet_prefix
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.group.name
  address_prefix       = var.gateway_subnet_prefix
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "PublicSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.group.name
  address_prefix       = var.public_subnet_prefix
}

resource "azurerm_subnet" "jumpbox_subnet" {
  name                 = "JumpboxSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.group.name
  address_prefix       = var.jumpbox_subnet_prefix
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "WebSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.group.name
  address_prefix       = var.web_subnet_prefix
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "DatabaseSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.group.name
  address_prefix       = var.database_subnet_prefix
}

resource "random_id" "diagnostics_id" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.group.name
    }   
    byte_length = 8
}

resource "azurerm_storage_account" "diagnostics" {
    name                        = "${var.diag_storage_prefix}${random_id.diagnostics_id.hex}"
    resource_group_name         = azurerm_resource_group.group.name
    location                    = var.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        role = "diagnostics"
    }
}

resource "azurerm_container_registry" "acr" {
  name                     = var.azure_container_registry_name
  location                 = var.location
  resource_group_name      = azurerm_resource_group.group.name
  sku                      = "Standard"
  admin_enabled            = true
}

##############################################################################
# * Azure Bastion
# resource "azurerm_public_ip" "bastion_ip" {
#   name                = "${var.bastion_name}-pip"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.group.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "bastion" {
#   name                = var.bastion_name
#   location            = var.location
#   resource_group_name = azurerm_resource_group.group.name

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.bastion_subnet.id
#     public_ip_address_id = azurerm_public_ip.bastion_ip.id
#   }
# }

##############################################################################
# * Jumpbox
resource "azurerm_network_security_group" "jumpbox_sg" {
  name                = "${var.jumpbox_name}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "jumpbox_ip" {
  name                = "${var.jumpbox_name}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "${var.jumpbox_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

  ip_configuration {
    name                          = "${var.jumpbox_name}-ipconfig"
    subnet_id                     = azurerm_subnet.jumpbox_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nic_sg_assoc" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_sg.id
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = var.jumpbox_name
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name
  size                = "Standard_B1ms"
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                  = "${var.jumpbox_name}-osdisk"
    storage_account_type  = "Standard_LRS"
    caching               = "ReadWrite"
  }
}

##############################################################################
# * Web Server
resource "azurerm_network_interface" "web_nic" {
  name                = "${var.web_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

  ip_configuration {
    name                          = "${var.web_name}-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = var.web_name
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name
  size                = "Standard_B1ms"
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.web_nic.id
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                  = "${var.web_name}-osdisk"
    storage_account_type  = "Standard_LRS"
    caching               = "ReadWrite"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diagnostics.primary_blob_endpoint
  }
}

##############################################################################
# * Application Gateway
resource "azurerm_public_ip" "app_ip" {
  name                = "${var.app_name}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_application_gateway" "app" {
  name                = "${var.app_name}gw"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "${var.app_name}-ipconfig"
    subnet_id = azurerm_subnet.public_subnet.id
  }

  frontend_port {
    name = "${var.app_name}-http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${var.app_name}-frontend-ipconfig"
    public_ip_address_id = azurerm_public_ip.app_ip.id
  }

  backend_address_pool {
    name          = "${var.app_name}-backend-pool"
    ip_addresses  = [
      azurerm_linux_virtual_machine.web.private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "${var.app_name}-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 32768
    protocol              = "Http"
    request_timeout       = 10
  }

  http_listener {
    name                           = "${var.app_name}-http-listener"
    frontend_ip_configuration_name = "${var.app_name}-frontend-ipconfig"
    frontend_port_name             = "${var.app_name}-http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${var.app_name}-http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.app_name}-http-listener"
    backend_address_pool_name  = "${var.app_name}-backend-pool"
    backend_http_settings_name = "${var.app_name}-http-settings"
  }
}

##############################################################################
# * Azure MySQL Database
resource "azurerm_mysql_server" "mysql" {
  name                = "${var.db_name}-svr"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

  sku_name = "GP_Gen5_2"

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = var.admin_username
  administrator_login_password = "Pass@word1!"
  version                      = "5.7"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_mysql_database" "db" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.group.name
  server_name         = azurerm_mysql_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}