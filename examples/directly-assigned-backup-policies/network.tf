provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "main" {
  name                = "d-backup-vnet"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  address_space = ["10.0.0.0/16"]

}

resource "azurerm_subnet" "main" {
  name                 = "default"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name

  address_prefixes = ["10.0.0.0/24"]
}
