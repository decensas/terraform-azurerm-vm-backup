resource "azurerm_resource_group" "vm" {
  name     = "d-vm-backup-vm-directly-assigned"
  location = "norwayeast"
}

resource "azurerm_resource_group" "backup" {
  name     = "d-vm-backup-directly-assigned"
  location = azurerm_resource_group.vm.location
}

module "backup" {
  source = "../../"
  #version = "0.1.0"

  resource_group_name = azurerm_resource_group.backup.name
  location            = azurerm_resource_group.backup.location
  storage_mode_type   = "LocallyRedundant"
  soft_delete_enabled = false

  backup_policies = {
    default_policy = {
      backup_time      = "20:00"
      backup_frequency = "Weekly"

      instant_restore_retention_days = 10

      retention = {
        weekly_backups_retention = 20 # retains 20 weekly backups at a time
        weekdays                 = ["Friday"]
      }
      protected_virtual_machines = azurerm_windows_virtual_machine.compute
    }

    daily_backup = {
      backup_time      = "20:00"
      backup_frequency = "Daily"

      retention = {
        daily_backups_retention = 10 # Retains 10 daily backups at a time
      }

      protected_virtual_machines = azurerm_windows_virtual_machine.database
    }
  }

  tags = {
    environment = "Demo"
  }
}
