resource "azurerm_recovery_services_vault" "vault" {
  name                = var.recovery_services_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  public_network_access_enabled = var.public_network_access_enabled
  storage_mode_type             = var.storage_mode_type
  cross_region_restore_enabled  = var.cross_region_restore_enabled
  soft_delete_enabled           = var.soft_delete_enabled
  immutability                  = var.immutability

  dynamic "identity" {
    for_each = var.encryption_with_cmk ? [""] : []
    content {
      type         = var.identity
      identity_ids = var.identity_ids
    }
  }

  dynamic "encryption" {
    for_each = var.encryption_with_cmk ? [""] : []
    content {
      key_id                            = var.key_vault_key_id
      infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
      user_assigned_identity_id         = var.user_assigned_identity_id_encryption
      use_system_assigned_identity      = var.user_assigned_identity_id_encryption == null ? true : false
    }
  }

  monitoring {
    alerts_for_all_job_failures_enabled            = var.rsv_alerts_for_all_job_failures_enabled
    alerts_for_critical_operation_failures_enabled = var.rsv_alerts_for_critical_operation_failures_enabled
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "backup" {
  count               = var.manage_private_endpoint ? 1 : 0
  name                = "${var.recovery_services_vault_name}-endpoint"
  location            = azurerm_recovery_services_vault.vault.location
  resource_group_name = azurerm_recovery_services_vault.vault.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.recovery_services_vault_name}-connection"
    private_connection_resource_id = azurerm_recovery_services_vault.vault.id
    subresource_names              = ["AzureBackup"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.manage_dns_zone ? [""] : []
    content {
      name                 = var.private_dns_zone_group_name
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
}

resource "azurerm_backup_policy_vm" "backup_policy" {
  for_each                       = var.backup_policies
  name                           = each.key
  resource_group_name            = azurerm_recovery_services_vault.vault.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.vault.name
  timezone                       = each.value.timezone
  policy_type                    = each.value.policy_type
  instant_restore_retention_days = each.value.instant_restore_retention_days


  backup {
    frequency     = each.value.backup_frequency
    time          = each.value.backup_time
    hour_interval = each.value.backup_frequency == "Daily" ? each.value.backup_hour_interval : null
    hour_duration = each.value.backup_frequency == "Daily" ? each.value.backup_hour_duration : null
    weekdays      = each.value.backup_frequency == "Weekly" ? each.value.retention.weekdays : null
  }

  dynamic "retention_daily" {
    for_each = each.value.backup_frequency == "Daily" || each.value.retention.daily_backups_retention != null ? [""] : []
    content {
      count = each.value.retention.daily_backups_retention
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.backup_frequency == "Weekly" || each.value.retention.weekly_backups_retention != null ? [""] : []
    content {
      count    = each.value.retention.weekly_backups_retention
      weekdays = each.value.retention.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = each.value.retention.monthly_backups_retention != null ? [""] : []
    content {
      count             = each.value.retention.monthly_backups_retention
      weekdays          = each.value.retention.months_weekdays
      weeks             = each.value.retention.months_weeks
      days              = each.value.retention.months_days
      include_last_days = each.value.retention.include_last_days
    }
  }

  dynamic "retention_yearly" {
    for_each = each.value.retention.yearly_backups_retention != null ? [""] : []
    content {
      count             = each.value.retention.yearly_backups_retention
      months            = each.value.retention.yearly_months
      weekdays          = each.value.retention.yearly_weekdays
      weeks             = each.value.retention.yearly_weeks
      days              = each.value.retention.yearly_days
      include_last_days = each.value.retention.include_last_days
    }
  }
}

locals {
  # Flattens backup policy object to an iterable value 
  # <key>#<policy_name> = {
  #   vm_id = <vm_id>
  #   backup_policy_name = <backup_policy_name>
  # }
  flattened_list_of_vms_and_policies = merge([for policy_name, policy_object in var.backup_policies : {
    for key, vm in policy_object.protected_virtual_machines :
    "${key}#${policy_name}" => {
      vm_id              = vm.id,
      backup_policy_name = policy_name
  } }]...)
}

resource "azurerm_backup_protected_vm" "backup_vms" {
  for_each            = local.flattened_list_of_vms_and_policies
  resource_group_name = azurerm_recovery_services_vault.vault.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = each.value.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy[each.value.backup_policy_name].id
}

