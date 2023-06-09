output "vault" {
  description = "Recovery Services Vault object created by this module."
  value       = azurerm_recovery_services_vault.vault
}

output "policy" {
  description = "A map of backup policy objects created by this module."
  value       = azurerm_backup_policy_vm.backup_policy
}

