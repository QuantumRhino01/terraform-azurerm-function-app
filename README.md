# Azure Function App
[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-yellow.svg)](NOTICE) [![Apache V2 License](https://img.shields.io/badge/license-Apache%20V2-orange.svg)](LICENSE) [![TF Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/claranet/function-app/azurerm/)

This Terraform module creates an [Azure Function App](https://docs.microsoft.com/en-us/azure/azure-functions/)
with its [App Service Plan](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans), 
a consumption plan by default.
A [Storage Account](https://docs.microsoft.com/en-us/azure/storage/) and an [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) 
are required and are created if not provided.
This module allows to deploy a application from a local or remote ZIP file that will be stored on the associated storage
account.

You can create an Azure Function without plan by using the submodule `modules/functionapp`.

Azure Functions v3 are now supported by this module and is the default one.

## Limitations

Based on a current limitation, you cannot mix Windows and Linux apps in the same resource group.

Limitations documentation: [docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-intro#limitations](https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-intro#limitations)

<!-- BEGIN_TF_DOCS -->
## Global versioning rule for Claranet Azure modules

| Module version | Terraform version | AzureRM version |
| -------------- | ----------------- | --------------- |
| >= 6.x.x       | 1.x               | >= 3.0          |
| >= 5.x.x       | 0.15.x            | >= 2.0          |
| >= 4.x.x       | 0.13.x / 0.14.x   | >= 2.0          |
| >= 3.x.x       | 0.12.x            | >= 2.0          |
| >= 2.x.x       | 0.12.x            | < 2.0           |
| <  2.x.x       | 0.11.x            | < 2.0           |

## Usage

This module is optimized to work with the [Claranet terraform-wrapper](https://github.com/claranet/terraform-wrapper) tool
which set some terraform variables in the environment needed by this module.
More details about variables set by the `terraform-wrapper` available in the [documentation](https://github.com/claranet/terraform-wrapper#environment).

```hcl
module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "x.x.x"

  azure_region = var.azure_region
}

module "rg" {
  source  = "claranet/rg/azurerm"
  version = "x.x.x"

  location    = module.azure_region.location
  client_name = var.client_name
  environment = var.environment
  stack       = var.stack
}

module "logs" {
  source  = "claranet/run-common/azurerm//modules/logs"
  version = "x.x.x"

  client_name         = var.client_name
  environment         = var.environment
  stack               = var.stack
  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
  resource_group_name = module.rg.resource_group_name
}

### Windows
module "function_app_windows" {
  source  = "claranet/function-app/azurerm"
  version = "x.x.x"

  client_name         = var.client_name
  environment         = var.environment
  stack               = var.stack
  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
  resource_group_name = module.rg.resource_group_name

  name_prefix = "hello"

  app_service_plan_os = "Windows"

  function_app_application_settings = {
    "tracker_id"      = "AJKGDFJKHFDS"
    "backend_api_url" = "https://backend.domain.tld/api"
  }

  storage_account_identity_type = "SystemAssigned"

  logs_destinations_ids = [
    module.logs.logs_storage_account_id,
    module.logs.log_analytics_workspace_id
  ]

  extra_tags = {
    foo = "bar"
  }
}

### Linux
module "function_app_linux" {
  source  = "claranet/function-app/azurerm"
  version = "x.x.x"

  client_name         = var.client_name
  environment         = var.environment
  stack               = var.stack
  location            = module.azure_region.location
  location_short      = module.azure_region.location_short
  resource_group_name = module.rg.resource_group_name

  name_prefix = "hello"

  app_service_plan_os         = "Linux"
  function_language_for_linux = "python"
  function_app_version        = 3

  function_app_application_settings = {
    "tracker_id"      = "AJKGDFJKHFDS"
    "backend_api_url" = "https://backend.domain.tld/api"
  }

  storage_account_identity_type = "SystemAssigned"

  logs_destinations_ids = [
    module.logs.logs_storage_account_id,
    module.logs.log_analytics_workspace_id
  ]

  extra_tags = {
    foo = "bar"
  }
}
```

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| app\_service\_plan | claranet/app-service-plan/azurerm | 5.1.0 |
| function\_app | ./modules/functionapp | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_service\_plan\_custom\_name | Custom name for app service plan | `string` | `""` | no |
| app\_service\_plan\_extra\_tags | Extra tags to add to App Service Plan | `map(string)` | `{}` | no |
| app\_service\_plan\_name\_prefix | App Service Plan name prefix | `string` | `""` | no |
| app\_service\_plan\_os | App Service Plan OS for dedicated plans, can be "Linux" or "Windows" | `string` | n/a | yes |
| app\_service\_plan\_reserved | Flag indicating if dedicated App Service Plan should be reserved | `string` | `"false"` | no |
| app\_service\_plan\_sku | App Service Plan sku if created, consumption plan by default | `map(string)` | <pre>{<br>  "size": "Y1",<br>  "tier": "Dynamic"<br>}</pre> | no |
| application\_insights\_custom\_name | Custom name for application insights deployed with function app | `string` | `""` | no |
| application\_insights\_daily\_data\_cap | Daily data volume cap (in GB) for Application Insights | `number` | `null` | no |
| application\_insights\_daily\_data\_cap\_notifications\_disabled | Disable email notifications when data volume cap is met | `bool` | `null` | no |
| application\_insights\_enabled | Enable or disable the Application Insights deployment | `bool` | `true` | no |
| application\_insights\_extra\_tags | Extra tags to add to Application Insights | `map(string)` | `{}` | no |
| application\_insights\_force\_customer\_storage\_for\_profiler | Enable Application Insights component to force users to create their own storage account for profiling | `bool` | `false` | no |
| application\_insights\_id | ID of the existing Application Insights to use instead of deploying a new one. | `string` | `null` | no |
| application\_insights\_internet\_ingestion\_enabled | Enable ingestion support from Application Insights component over the Public Internet | `bool` | `true` | no |
| application\_insights\_internet\_query\_enabled | Enable querying support from Application Insights component over the Public Internet | `bool` | `true` | no |
| application\_insights\_ip\_masking\_disabled | Disable IP masking in logs | `bool` | `false` | no |
| application\_insights\_local\_authentication\_disabled | Disable Non-Azure AD based Auth | `bool` | `false` | no |
| application\_insights\_log\_analytics\_workspace\_id | ID of the Log Analytics Workspace to be used with Application Insights | `string` | `null` | no |
| application\_insights\_name\_prefix | Application Insights name prefix | `string` | `""` | no |
| application\_insights\_retention | Specify retention period (in days) for logs | `number` | `90` | no |
| application\_insights\_sampling\_percentage | Percentage of data produced by the monitored application sampled for Application Insights telemetry | `number` | `null` | no |
| application\_insights\_type | Application Insights type if need to be generated. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights#application_type | `string` | `"web"` | no |
| application\_zip\_package\_path | Local or remote path of a zip package to deploy on the Function App | `string` | `null` | no |
| authorized\_ips | IPs restriction for Function in CIDR format. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#ip_restriction | `list(string)` | `[]` | no |
| authorized\_service\_tags | Service Tags restriction for Function. See documentation https://www.terraform.io/docs/providers/azurerm/r/function_app.html#ip_restriction | `list(string)` | `[]` | no |
| authorized\_subnet\_ids | Subnets restriction for Function. See documentation https://www.terraform.io/docs/providers/azurerm/r/function_app.html#ip_restriction | `list(string)` | `[]` | no |
| builtin\_logging\_enabled | Should the built-in logging of this Function App be enabled? | `bool` | `true` | no |
| client\_cert\_mode | The mode of the Function App's client certificates requirement for incoming requests | `string` | `null` | no |
| client\_name | Client name/account used in naming | `string` | n/a | yes |
| custom\_diagnostic\_settings\_name | Custom name of the diagnostics settings, name will be 'default' if not set. | `string` | `"default"` | no |
| default\_tags\_enabled | Option to enable or disable default tags | `bool` | `true` | no |
| environment | Project environment | `string` | n/a | yes |
| extra\_tags | Extra tags to add | `map(string)` | `{}` | no |
| function\_app\_application\_settings | Function App application settings | `map(string)` | `{}` | no |
| function\_app\_custom\_name | Custom name for function app | `string` | `""` | no |
| function\_app\_extra\_tags | Extra tags to add to Function App | `map(string)` | `{}` | no |
| function\_app\_name\_prefix | Function App name prefix | `string` | `""` | no |
| function\_app\_site\_config | Site config for Function App. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#site_config. IP restriction attribute is not managed in this block. | `any` | `{}` | no |
| function\_app\_version | Version of the function app runtime to use (Allowed values 2 or 3) | `number` | `3` | no |
| function\_app\_vnet\_integration\_enabled | Enable VNET integration with the Function App. `function_app_vnet_integration_subnet_id` is mandatory if enabled | `bool` | `false` | no |
| function\_app\_vnet\_integration\_subnet\_id | ID of the subnet to associate with the Function App (VNet integration) | `string` | `null` | no |
| function\_language\_for\_linux | Language of the Function App on Linux hosting, can be "dotnet", "node" or "python" | `string` | `"dotnet"` | no |
| https\_only | Disable http procotol and keep only https | `bool` | `true` | no |
| identity\_ids | UserAssigned Identities ID to add to Function App. Mandatory if type is UserAssigned | `list(string)` | `null` | no |
| identity\_type | Add an Identity (MSI) to the function app. Possible values are SystemAssigned or UserAssigned | `string` | `"SystemAssigned"` | no |
| ip\_restriction\_headers | IPs restriction headers for Function. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#headers | `map(list(string))` | `null` | no |
| location | Azure location for Function App and related resources | `string` | n/a | yes |
| location\_short | Short string for Azure location | `string` | n/a | yes |
| logs\_categories | Log categories to send to destinations. | `list(string)` | `null` | no |
| logs\_destinations\_ids | List of destination resources Ids for logs diagnostics destination. Can be Storage Account, Log Analytics Workspace and Event Hub. No more than one of each can be set. Empty list to disable logging. | `list(string)` | n/a | yes |
| logs\_metrics\_categories | Metrics categories to send to destinations. | `list(string)` | `null` | no |
| logs\_retention\_days | Number of days to keep logs on storage account | `number` | `30` | no |
| name\_prefix | Optional prefix for the generated name | `string` | `""` | no |
| name\_suffix | Optional suffix for the generated name | `string` | `""` | no |
| resource\_group\_name | Resource group name | `string` | n/a | yes |
| scm\_authorized\_ips | SCM IPs restriction for Function. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#scm_ip_restriction | `list(string)` | `[]` | no |
| scm\_authorized\_service\_tags | SCM Service Tags restriction for Function. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#scm_ip_restriction | `list(string)` | `[]` | no |
| scm\_authorized\_subnet\_ids | SCM subnets restriction for Function. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#scm_ip_restriction | `list(string)` | `[]` | no |
| scm\_ip\_restriction\_headers | IPs restriction headers for Function. See documentation https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#scm_ip_restriction | `map(list(string))` | `null` | no |
| stack | Project stack name | `string` | n/a | yes |
| storage\_account\_access\_key | Access key the storage account to use. If null a new storage account is created | `string` | `null` | no |
| storage\_account\_authorized\_ips | IPs restriction for Function storage account in CIDR format | `list(string)` | `[]` | no |
| storage\_account\_enable\_advanced\_threat\_protection | Boolean flag which controls if advanced threat protection is enabled, see [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-advanced-threat-protection?tabs=azure-portal) for more information. | `bool` | `false` | no |
| storage\_account\_enable\_https\_traffic\_only | Boolean flag which controls if https traffic only is enabled. | `bool` | `true` | no |
| storage\_account\_extra\_tags | Extra tags to add to Storage Account | `map(string)` | `{}` | no |
| storage\_account\_identity\_ids | Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account | `list(string)` | `null` | no |
| storage\_account\_identity\_type | Specifies the type of Managed Service Identity that should be configured on this Storage Account | `string` | `null` | no |
| storage\_account\_kind | Storage Account Kind | `string` | `"StorageV2"` | no |
| storage\_account\_min\_tls\_version | Storage Account minimal TLS version | `string` | `"TLS1_2"` | no |
| storage\_account\_name | Name of the Storage account to attach to function | `string` | `null` | no |
| storage\_account\_name\_prefix | Storage Account name prefix | `string` | `""` | no |
| storage\_account\_network\_bypass | Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of `Logging`, `Metrics`, `AzureServices`, or `None`. | `list(string)` | <pre>[<br>  "Logging",<br>  "Metrics",<br>  "AzureServices"<br>]</pre> | no |
| storage\_account\_network\_rules\_enabled | Enable Storage account network default rules for functions | `bool` | `true` | no |
| use\_caf\_naming | Use the Azure CAF naming provider to generate default resource name. `custom_name` override this if set. Legacy default name is used if this is set to `false`. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_service\_plan\_id | ID of the created App Service Plan |
| app\_service\_plan\_name | Name of the created App Service Plan |
| application\_insights\_app\_id | App ID of the associated Application Insights |
| application\_insights\_application\_type | Application Type of the associated Application Insights |
| application\_insights\_id | ID of the associated Application Insights |
| application\_insights\_instrumentation\_key | Instrumentation key of the associated Application Insights |
| application\_insights\_name | Name of the associated Application Insights |
| function\_app\_connection\_string | Connection string of the created Function App |
| function\_app\_id | ID of the created Function App |
| function\_app\_identity | Identity block output of the Function App |
| function\_app\_name | Name of the created Function App |
| function\_app\_outbound\_ip\_addresses | Outbound IP adresses of the created Function App |
| storage\_account\_id | ID of the associated Storage Account, empty if connection string provided |
| storage\_account\_name | Name of the associated Storage Account, empty if connection string provided |
| storage\_account\_network\_rules | Network rules of the associated Storage Account |
| storage\_account\_primary\_access\_key | Primary connection string of the associated Storage Account, empty if connection string provided |
| storage\_account\_primary\_connection\_string | Primary connection string of the associated Storage Account, empty if connection string provided |
| storage\_account\_secondary\_access\_key | Secondary connection string of the associated Storage Account, empty if connection string provided |
| storage\_account\_secondary\_connection\_string | Secondary connection string of the associated Storage Account, empty if connection string provided |
<!-- END_TF_DOCS -->

## Related documentation

Microsoft Azure Functions documentation: [github.com/Azure/Azure-Functions#documentation-1](https://github.com/Azure/Azure-Functions#documentation-1)
