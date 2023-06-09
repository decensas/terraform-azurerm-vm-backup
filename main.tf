resource "azurerm_recovery_services_vault" "vault" {
  name                = var.recovery_services_vault_name
  location            = var.backup_location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  public_network_access_enabled = var.public_network_access_enabled
  storage_mode_type             = var.storage_mode_type
  cross_region_restore_enabled  = var.cross_region_restore_enabled
  soft_delete_enabled           = var.soft_delete_enabled


  monitoring {
    alerts_for_all_job_failures_enabled            = var.rsv_alerts_for_all_job_failures_enabled
    alerts_for_critical_operation_failures_enabled = var.rsv_alerts_for_critical_operation_failures_enabled
  }

  tags = var.tags
}


resource "azurerm_backup_policy_vm" "backup_policy" {
  for_each                       = var.backup_policies
  name                           = each.key
  resource_group_name            = azurerm_recovery_services_vault.vault.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.vault.name
  timezone                       = each.value.timezone
  policy_type                    = each.value.policy_type
  instant_restore_retention_days = each.value.instant_days


  backup {
    frequency     = each.value.backup_frequency
    time          = each.value.backup_time
    hour_interval = each.value.backup_hour_interval
    hour_duration = each.value.backup_hour_duration
    weekdays      = each.value.weekdays
  }

  retention_daily {
    count = each.value.retention.daily_backups_retention
  }

  retention_weekly {
    count    = each.value.retention.weekly_backups_retention
    weekdays = each.value.retention.weekdays
  }

  retention_monthly {
    count             = each.value.retention.monthly_backups_retention
    weekdays          = each.value.retention.months_weekdays
    weeks             = each.value.retention.months_weeks
    days              = each.value.retention.months_days
    include_last_days = each.value.retention.include_last_days
  }

  retention_yearly {
    count             = each.value.retention.yearly_backups_retention
    months            = each.value.retention.yearly_months
    weekdays          = each.value.retention.yearly_weekdays
    weeks             = each.value.retention.yearly_weeks
    days              = each.value.retention.yearly_days
    include_last_days = each.value.retention.include_last_days
  }
}

locals {
  flattened_list_of_vms_and_policies = flatten([for policy_name, policy_object in var.backup_policies : [for vm_name in policy_object : "${policy_name}|${vm_name}"]])
}

resource "azurerm_backup_protected_vm" "backup_vms" {
  for_each            = toset(local.flattened_list_of_vms_and_policies)
  resource_group_name = azurerm_recovery_services_vault.vault.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = split("|", each.key)[1]
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy[split("|", each.key)[0]].id
}
