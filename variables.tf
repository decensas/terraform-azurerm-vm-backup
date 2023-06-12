variable "resource_group_name" {
  description = "The name of the resource group in which to deploy the backup resources."
  type        = string
}

variable "location" {
  description = "Name of location to where backups will be stored"
  type        = string
}

variable "recovery_services_vault_name" {
  type        = string
  description = "Name of Recovery Services Vault where backups will be stored."
  default     = "backup-rsv"
}

variable "sku" {
  type        = string
  description = "SKU of Recovery Services Vault, either 'Standard' or 'RS0'."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "RS0"], var.sku)
    error_message = "var.sku must be set to either 'Standard' or 'RS0'"
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable access to Recovery Services Vault from public networks or not."
  default     = false
}

variable "soft_delete_enabled" {
  type        = bool
  description = "Whether to enable soft delete on Recovery Services Vault"
  default     = true
}

variable "storage_mode_type" {
  type        = string
  description = "Storage type of the Recovery Services Vault. Must be one of 'GeoRedundant', 'LocallyRedundant' or 'ZoneRedundant'."
  default     = "GeoRedundant"

  validation {
    condition     = contains(["GeoRedundant", "LocallyRedundant", "ZoneRedundant"], var.storage_mode_type)
    error_message = "var.storage_mode_type must be one of 'GeoRedundant', 'LocallyRedundant' or 'ZoneRedundant'"
  }
}

variable "cross_region_restore_enabled" {
  type        = bool
  description = "Whether to enable cross region restore for Recovery Services Vault. For this to be true var.storage_mode_type must be set to GeoRedundant"
  default     = false
}

variable "identity" {
  type        = string
  description = "What identity to enable for the Recovery Service Vault. The identity is used when using Customer Managed Key (CMK for encryption) or accessing the vault using Private Endpoints. Available options are: 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'"
  default     = null

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], coalesce(var.identity, "SystemAssigned"))
    error_message = "var.identity must be one of: 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'"
  }
}

variable "identity_ids" {
  type        = list(string)
  description = "List of User Assigned Managed Identity IDs to be used by the Recovery Services Vault. Only relevant if var.identity is set to either 'SystemAssigned' or 'SystemAssigned, UserAssigned'."
  default     = null
}

variable "encryption_with_cmk" {
  type        = bool
  description = "Whether to manage encryption using Customer Managed Key (CMK) provisioned with var.key_vault_key_id. Relevant documentation: https://learn.microsoft.com/en-us/azure/backup/backup-encryption"
  default     = false
}

variable "key_vault_key_id" {
  type        = string
  description = "ID of key within Azure Key Vault. This should be the Customer Managed Key (CMK)"
  default     = null
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Whether to add an additional layer of encryption on the storage infrastructure"
  default     = false
}

variable "user_assigned_identity_id_encryption" {
  type        = string
  description = "User assigned ID to be used for additional encryption. Only relevant if var.encryption_with_cmk is enabled. System Assigned Identity for the Recovery Services Vault is used if no value is provided."
  default     = null
}

variable "rsv_alerts_for_all_job_failures_enabled" {
  type        = bool
  description = "Enabling/Disabling built-in Azure Monitor alerts for security scenarios and job failure scenarios. More details could be found [here](https://learn.microsoft.com/en-us/azure/backup/monitoring-and-alerts-overview)."
  default     = true
}

variable "rsv_alerts_for_critical_operation_failures_enabled" {
  type        = bool
  description = "Enabling/Disabling alerts from the older (classic alerts) solution. More details could be found [here](https://learn.microsoft.com/en-us/azure/backup/monitoring-and-alerts-overview)."
  default     = true
}

variable "backup_policies" {
  description = "A map of backup policy objects where the key is the name of the policy."
  type = map(object({
    timezone                       = optional(string, "UTC") # [Allowed values](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/)
    backup_time                    = string                  # Time of day to perform backup in 24h format, e.g. 23:00
    backup_frequency               = string                  # Frequency of backup, supported values 'Hourly', 'Daily', 'Weekly'
    policy_type                    = optional(string, "V2")  # set to V1 or V2, see [here](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-enhanced-policy?tabs=azure-portal)
    instant_restore_retention_days = optional(number)        # Between 1-5 for var.policy_type V1, 1-30 for V2
    backup_hour_interval           = optional(number)        # Interval of which backup is triggered. Allowed values are: 4, 6, 8 or 12. Used if backup_frequency is set to Hourly.
    backup_hour_duration           = optional(number)        # Duration of the backup window in hours. Value between 4 and 24. Used if backup_frequency is Hourly. Must be a multiplier of backup_hour_interval
    retention = optional(object({
      daily_backups_retention = optional(number) # Number of daily backups to retain, must be between 7-9999. Required if backup_frequency is Daily

      weekly_backups_retention = optional(number)       # Number of weekly backups to retain, must be between 1-9999. 
      weekdays                 = optional(list(string)) # The day in the week of backups to retain. Used for weekly retention.

      monthly_backups_retention = optional(number)       # Number of monthly backups to retain, must be between 1-9999. 
      months_weekdays           = optional(list(string)) # The day in the week of backups to retain. Used for monthly retention configuration
      months_weeks              = optional(list(string)) # Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for monthly retention configuration
      months_days               = optional(list(number)) # The days in the month to retain backups of. Must be between 1-31. Used for monthly retenion configuration
      months_include_last_days  = optional(bool, false)  # Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set. 

      yearly_backups_retention = optional(number)       # Number of yearly backups to retain, must be between 1-9999. 
      yearly_months            = optional(list(string)) # The months of the year to retain backups of. Values most be names of the month with capital case. Used for yearly retention configuration
      yearly_weekdays          = optional(list(string)) # The day in the week of backups to retain. Used for yearly retention configuration
      yearly_weeks             = optional(list(string)) # Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for yearly retention configuration
      yearly_days              = optional(list(number)) # The days in the month to retain backups of. Must be between 1-31. Used for monthly retention configuration
      yearly_include_last_days = optional(bool, false)  # Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set. 

    }))
    protected_virtual_machines = optional(list(object({
      name = string
      id   = string
    })))
  }))
}

variable "azure_policy_id" {
  type        = string
  description = "(Optional) ID of Azure policy to use for automatically assignment of backup policies to VMs based on tags."
  default     = ""
}

variable "azure_policy_scope" {
  type        = string
  description = "(Optional) What scope to assign an Azure policy to assign backup policies to VMs on. Must be one of 'management_group', 'subscription' or 'resource_group'"
  default     = "subscription"

  validation {
    condition     = contains(["management_group", "subscription", "resource_group"], var.azure_policy_scope)
    error_message = "The scope must be either of 'management_group', 'subscription' or 'resource_group'"
  }
}

variable "azure_policy_scope_id" { # azure_policy_scope and this one should be combined
  type        = string
  description = "(Optional) ID of scope specified within var.azure_policy_scope. Required if var.azure_policy_scope is set."
  default     = ""
}

variable "tag_key" {
  type        = string
  description = "(Optional) Name of the Azure resource tag key that will be read by Azure policies to decide which backup policy should be applied. The key is the backup policy and the value is the Azure resource tag value. Only used when backup policies should b applied to virtual machines using an Azure policy."
  default     = "backup policy"
}

variable "tag_value" {
  type        = map(string)
  description = "(Optional) A key-value map correlating which backup policies matches which Azure resource tag. The key is the backup policy and the value is the Azure resource tag value. Only used when backup policies should b applied to virtual machines using an Azure policy."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags that will be applied to all deployed resources."
  default     = {}
}
