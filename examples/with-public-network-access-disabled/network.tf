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

resource "azurerm_private_dns_zone" "backup" {
  name                = "privatelink.${azurerm_resource_group.vm.location}.backup.windowsazure.com"
  resource_group_name = azurerm_resource_group.vm.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "backup" {
  name                  = "backup-link"
  resource_group_name   = azurerm_resource_group.vm.name
  private_dns_zone_name = azurerm_private_dns_zone.backup.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
