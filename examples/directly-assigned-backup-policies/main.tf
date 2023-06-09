module "backup" {
  source  = "decensas/azure-virtual-machine-backup/azurerm"
  version = "0.1.0"

  resource_group_name = azurerm_resource_group.main.name
  backup_location     = "westeurope"
  storage_mode_type   = "LocallyRedundant"

  backup_policies = {
    default_policy = {
      backup_time      = "20:00"
      backup_frequency = "Weekly"

      instant_restore_retention_days = 10

      retention = {
        weekly_backup_retention = 20 # retains 20 weekly backups at a time
        weekdays                = "Friday"
      }
      protected_virtual_machine_ids = [azurerm_windows_virtual_machine.main[*]]
    }

    daily_backup = {
      backup_time      = "20:00"
      backup_frequency = "Daily"

      retention = {
        daily_backups_retention = 10 # Retains 10 daily backups at a time
      }

      protected_virtual_machine_ids = [azurerm_windows_virtual_machine.main[2]]
    }
  }

  tags = {
    environment = "Demo"
  }
}
