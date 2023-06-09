provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "d-vm-backup-directly-assigned"
  location = "norwayeast"
}

resource "azurerm_virtual_network" "main" {
  name                = "d-backup-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  address_space = ["10.0.0.0/16"]

}

resource "azurerm_subnet" "main" {
  name                 = "default"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name

  address_prefixes = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "d-backup-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
