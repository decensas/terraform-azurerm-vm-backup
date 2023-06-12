# azurerm-azure-vm-backup
Terraform module for management of Azure Virtual Machine backup. Supports creating Recovery Services Vault, multiple backup policies and assigning backup policies to specific VMs.

## Examples
Here are some short examples with referenced resources cut out. See [examples](./examples)-directory for full examples.

### Directly assigned backup policies 
This example features the deployment of two backup policies `default_policy` and `daily_backup`. 

`default_policy` is run weekly on Fridays and is assigned all virtual machines.

`daily_backup` is run daily and is assigned only virtual machine number 2.

See full example [here](./examples/directly-assigned-backup-policies).
```terraform
module "backup" {
  source  = "decensas/azure-virtual-machine-backup/azurerm"
  version = "0.1.0"
 
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
      protected_virtual_machines = [azurerm_windows_virtual_machine.main[1], azurerm_windows_virtual_machine.main[3]]
    }

    daily_backup = {
      backup_time      = "20:00"
      backup_frequency = "Daily"

      retention = {
        daily_backups_retention = 10 # Retains 10 daily backups at a time
      }

      protected_virtual_machines = [azurerm_windows_virtual_machine.main[2]]
    }
  }

  tags = {
    environment = "Demo"
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.8 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_backup_policy_vm.backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm) | resource |
| [azurerm_backup_protected_vm.backup_vms](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) | resource |
| [azurerm_private_endpoint.backup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_recovery_services_vault.vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_policies"></a> [backup\_policies](#input\_backup\_policies) | A map of backup policy objects where the key is the name of the policy. [Review](#var.backup\_policies) for comprehensive documentation | <pre>map(object({<br>    timezone                       = optional(string, "UTC") # [Allowed values](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/)<br>    backup_time                    = string                  # Time of day to perform backup in 24h format, e.g. 23:00<br>    backup_frequency               = string                  # Frequency of backup, supported values 'Hourly', 'Daily', 'Weekly'<br>    policy_type                    = optional(string, "V2")  # set to V1 or V2, see [here](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-enhanced-policy?tabs=azure-portal)<br>    instant_restore_retention_days = optional(number)        # Between 1-5 for var.policy_type V1, 1-30 for V2<br>    backup_hour_interval           = optional(number)        # Interval of which backup is triggered. Allowed values are: 4, 6, 8 or 12. Used if backup_frequency is set to Hourly.<br>    backup_hour_duration           = optional(number)        # Duration of the backup window in hours. Value between 4 and 24. Used if backup_frequency is Hourly. Must be a multiplier of backup_hour_interval<br>    retention = optional(object({<br>      daily_backups_retention = optional(number) # Number of daily backups to retain, must be between 7-9999. Required if backup_frequency is Daily<br><br>      weekly_backups_retention = optional(number)       # Number of weekly backups to retain, must be between 1-9999. <br>      weekdays                 = optional(list(string)) # The day in the week of backups to retain. Used for weekly retention.<br><br>      monthly_backups_retention = optional(number)       # Number of monthly backups to retain, must be between 1-9999. <br>      months_weekdays           = optional(list(string)) # The day in the week of backups to retain. Used for monthly retention configuration<br>      months_weeks              = optional(list(string)) # Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for monthly retention configuration<br>      months_days               = optional(list(number)) # The days in the month to retain backups of. Must be between 1-31. Used for monthly retenion configuration<br>      months_include_last_days  = optional(bool, false)  # Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set. <br><br>      yearly_backups_retention = optional(number)       # Number of yearly backups to retain, must be between 1-9999. <br>      yearly_months            = optional(list(string)) # The months of the year to retain backups of. Values most be names of the month with capital case. Used for yearly retention configuration<br>      yearly_weekdays          = optional(list(string)) # The day in the week of backups to retain. Used for yearly retention configuration<br>      yearly_weeks             = optional(list(string)) # Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for yearly retention configuration<br>      yearly_days              = optional(list(number)) # The days in the month to retain backups of. Must be between 1-31. Used for monthly retention configuration<br>      yearly_include_last_days = optional(bool, false)  # Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set. <br><br>    }))<br>    protected_virtual_machines = optional(map(object({<br>      name = string<br>      id   = string<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_cross_region_restore_enabled"></a> [cross\_region\_restore\_enabled](#input\_cross\_region\_restore\_enabled) | Whether to enable cross region restore for Recovery Services Vault. For this to be true var.storage\_mode\_type must be set to GeoRedundant | `bool` | `false` | no |
| <a name="input_encryption_with_cmk"></a> [encryption\_with\_cmk](#input\_encryption\_with\_cmk) | Whether to manage encryption using Customer Managed Key (CMK) provisioned with var.key\_vault\_key\_id. Relevant documentation: https://learn.microsoft.com/en-us/azure/backup/backup-encryption | `bool` | `false` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | What identity to enable for the Recovery Service Vault. The identity is used when using Customer Managed Key (CMK for encryption) or accessing the vault using Private Endpoints. Available options are: 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'. Required if encryption\_with\_cmk is enabled. | `string` | `"SystemAssigned"` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | List of User Assigned Managed Identity IDs to be used by the Recovery Services Vault. Only relevant if var.identity is set to either 'SystemAssigned' or 'SystemAssigned, UserAssigned'. | `list(string)` | `null` | no |
| <a name="input_immutability"></a> [immutability](#input\_immutability) | Whether you want vault to be immutable. Allowed values are: 'Locked', 'Unlocked' or 'Disabled'. Review https://learn.microsoft.com/en-us/azure/backup/backup-azure-immutable-vault-concept?tabs=recovery-services-vault | `string` | `"Disabled"` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | Whether to add an additional layer of encryption on the storage infrastructure | `bool` | `false` | no |
| <a name="input_key_vault_key_id"></a> [key\_vault\_key\_id](#input\_key\_vault\_key\_id) | ID of key within Azure Key Vault. This should be the Customer Managed Key (CMK) | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Name of location to where backups will be stored | `string` | n/a | yes |
| <a name="input_manage_dns_zone"></a> [manage\_dns\_zone](#input\_manage\_dns\_zone) | Whether to manage private DNS zone or not for Recovery Services Vault | `bool` | `true` | no |
| <a name="input_manage_private_endpoint"></a> [manage\_private\_endpoint](#input\_manage\_private\_endpoint) | Whether this module will manage a private endpoint for the Recovery Service Vault | `bool` | `false` | no |
| <a name="input_private_dns_zone_group_name"></a> [private\_dns\_zone\_group\_name](#input\_private\_dns\_zone\_group\_name) | Name of Azure Private DNS zone group for resolving private endpoint. Only relevant if var.private\_endpoint\_subnet\_id is set | `string` | `"backup-dns-zone"` | no |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | A list of private DNS zone IDs to add DNS entry to. Required if var.manage\_dns\_zone is true | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | Subnet ID of subnet to deploy Private Endpoint in. Required if public\_network\_access\_enabled is diabled | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable access to Recovery Services Vault from public networks or not. Requires configuration of a Private Endpoint and DNS resolve for backup operations and vault access. | `bool` | `false` | no |
| <a name="input_recovery_services_vault_name"></a> [recovery\_services\_vault\_name](#input\_recovery\_services\_vault\_name) | Name of Recovery Services Vault where backups will be stored. | `string` | `"backup-rsv"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to deploy the backup resources. | `string` | n/a | yes |
| <a name="input_rsv_alerts_for_all_job_failures_enabled"></a> [rsv\_alerts\_for\_all\_job\_failures\_enabled](#input\_rsv\_alerts\_for\_all\_job\_failures\_enabled) | Enabling/Disabling built-in Azure Monitor alerts for security scenarios and job failure scenarios. More details could be found [here](https://learn.microsoft.com/en-us/azure/backup/monitoring-and-alerts-overview). | `bool` | `true` | no |
| <a name="input_rsv_alerts_for_critical_operation_failures_enabled"></a> [rsv\_alerts\_for\_critical\_operation\_failures\_enabled](#input\_rsv\_alerts\_for\_critical\_operation\_failures\_enabled) | Enabling/Disabling alerts from the older (classic alerts) solution. More details could be found [here](https://learn.microsoft.com/en-us/azure/backup/monitoring-and-alerts-overview). | `bool` | `true` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | SKU of Recovery Services Vault, either 'Standard' or 'RS0'. | `string` | `"Standard"` | no |
| <a name="input_soft_delete_enabled"></a> [soft\_delete\_enabled](#input\_soft\_delete\_enabled) | Whether to enable soft delete on Recovery Services Vault | `bool` | `true` | no |
| <a name="input_storage_mode_type"></a> [storage\_mode\_type](#input\_storage\_mode\_type) | Storage type of the Recovery Services Vault. Must be one of 'GeoRedundant', 'LocallyRedundant' or 'ZoneRedundant'. | `string` | `"GeoRedundant"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Tags that will be applied to all deployed resources. | `map(string)` | `{}` | no |
| <a name="input_user_assigned_identity_id_encryption"></a> [user\_assigned\_identity\_id\_encryption](#input\_user\_assigned\_identity\_id\_encryption) | User assigned ID to be used for additional encryption. Only relevant if var.encryption\_with\_cmk is enabled. System Assigned Identity for the Recovery Services Vault is used if no value is provided. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy"></a> [policy](#output\_policy) | A map of backup policy objects created by this module. |
| <a name="output_vault"></a> [vault](#output\_vault) | Recovery Services Vault object created by this module. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## var.backup_policy

`var.backup_policy` is a complex structure and require additional documentation.
The outer layer is a key-value map where the key is the name of the backup policy and its value is a complex object describing the policy and its assignees.

```terraform
<policy_name> => { <policy_configuration> }
```

### Backup policy configuration
The backup policy configuration options are as follows:

| Name | Type | Description | Default | Required |
|---|---|---|---|---|
| timezone | `string` | [Allowed values](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/) | "UTC" | Optional |
| backup_time |  `string` | Time of day to perform backup in 24h format, e.g. 23:00 | n/a | Required |
| backup_frequency | `string` | Frequency of backup, supported values 'Hourly', 'Daily', 'Weekly' | n/a | Required |
| policy_type | `string` | Available values are 'V1' or 'V2', [Review](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-enhanced-policy?tabs=azure-portal) | n/a | Optional |
| instant_restore_retention_days | `number` | Between 1-5 for var.policy_type V1, 1-30 for V2 | n/a | Optional |
| backup_hour_interval | `number` | Interval of which backup is triggered. Allowed values are: 4, 6, 8 or 12. Used if backup_frequency is set to Hourly. | n/a | Optional |
| backup_hour_duration | `number` | Duration of the backup window in hours. Value between 4 and 24. Used if backup_frequency is Hourly. Must be a multiplier of backup_hour_interval | n/a | Optional |
| protected_virtual_machines | <pre>map(object({<br>  name = string<br>  id   = string<br>})</pre> | A map describing which VMs to assign backup policy to. The key should describe the VM e.g. its name, avoid retrieving the value from an Azure Resource to avoid dependency issues. The value is an object containing VM name and ID | n/a | Optional |
| retention | <pre>object({\<attributes\>})</pre> | Describing retention settings for the policy. | n/a | Optional |



### Retention configuration
Furthermore the retention configuration options are as follows:

| Name | Type | Description | Default | Required |
|---|---|---|---|---|
| daily_backups_retention | `number` | Number of daily backups to retain, must be between 7-9999. Required if backup_frequency is Daily | n/a | Optional |
| weekly_backups_retention | `number` | Number of weekly backups to retain, must be between 1-9999 | n/a | Optional |
| weekdays | `list(string)` | The day in the week of backups to retain. Used for weekly retention. E.g. "Monday" or "Friday" | n/a | Optional |
| monthly_backups_retention | `number` | Number of monthly backups to retain, must be between 1-9999 | n/a | Optional |
| months_weekdays | `list(string)` | The day in the week of backups to retain. Used for monthly retention configuration | n/a | Optional |
| months_weeks | `list(string)` | Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for monthly retention configuration | n/a | Optional |
| months_days | `list(number)` | The days in the month to retain backups of. Must be between 1-31. Used for monthly retention configuration | n/a | Optional |
| months_include_last_days | `bool` | Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set | false | Optional |
| yearly_backups_retention | `number` | Number of yearly backups to retain, must be between 1-9999 | n/a | Optional |
| yearly_months | `list(string)` | The months of the year to retain backups of. Values most be names of the month with capital case. Used for yearly retention configuration | n/a | Optional |
| yearly_weekdays | `list(string)`) | The day in the week of backups to retain. Used for yearly retention configuration | n/a | Optional |
| yearly_weeks | `list(string)` | Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for yearly retention configuration | n/a | Optional |
| yearly_days | `list(number)` | The days in the month to retain backups of. Must be between 1-31. Used for monthly retention configuration | n/a | Optional |
| yearly_include_last_days | `bool` | Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set |  |  |
|  |  |  |  |  |