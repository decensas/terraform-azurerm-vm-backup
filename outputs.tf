output "vault" {
  value = azurerm_recovery_services_vault.vault
}

output "policy" {
  value = azurerm_backup_policy_vm.backup_policy
}

