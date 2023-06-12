resource "azurerm_management_group_policy_assignment" "backup" {
  count                = var.enable_dynamic_backup_policy_assignment && one(keys(var.azure_policy_scope)) == "management_group" ? 1 : 0
  name                 = "backup-policy-assignment"
  display_name         = ""
  description          = ""
  policy_definition_id = var.azure_policy_id
  management_group_id  = var.azure_policy_scope["management_group"]

  parameters = ""

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_subscription_policy_assignment" "backup" {
  count                = var.enable_dynamic_backup_policy_assignment && one(keys(var.azure_policy_scope)) == "subscription" ? 1 : 0
  name                 = "backup-policy-assignment"
  display_name         = ""
  description          = ""
  policy_definition_id = var.azure_policy_id
  subscription_id      = var.azure_policy_scope["subscription"]

  parameters = ""

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_resource_group_policy_assignment" "backup" {
  count                = var.enable_dynamic_backup_policy_assignment && one(keys(var.azure_policy_scope)) == "resource_group" ? 1 : 0
  name                 = "backup-policy-assignment"
  display_name         = ""
  description          = ""
  policy_definition_id = var.azure_policy_id
  resource_group_id    = var.azure_policy_scope["resource_group"]

  parameters = ""

  identity {
    type = "SystemAssigned"
  }
}
