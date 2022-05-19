# Data Service Plan
data "azurerm_service_plan" "plan" {
  name                = element(split("/", var.service_plan_id), 8)
  resource_group_name = var.resource_group_name
}

# Function App
resource "azurerm_linux_function_app" "linux_function" {
  name = local.function_app_name

  service_plan_id     = var.service_plan_id
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account_name       = local.storage_account_name
  storage_account_access_key = var.storage_account_access_key == null ? azurerm_storage_account.storage[0].primary_access_key : var.storage_account_access_key
  # storage_uses_managed_identity = 
  # storage_key_vault_secret_id =

  functions_extension_version = "~${var.function_app_version}"

  app_settings = merge(
    local.default_application_settings,
    var.function_app_application_settings,
  )

  dynamic "site_config" {
    for_each = [local.site_config]
    content {
      always_on                = lookup(site_config.value, "always_on", null)
      app_command_line         = lookup(site_config.value, "app_command_line", null)
      default_documents        = lookup(site_config.value, "default_documents", null)
      ftps_state               = lookup(site_config.value, "ftps_state", "Disabled")
      health_check_path        = lookup(site_config.value, "health_check_path", null)
      http2_enabled            = lookup(site_config.value, "http2_enabled", null)
      managed_pipeline_mode    = lookup(site_config.value, "managed_pipeline_mode", null)
      minimum_tls_version      = lookup(site_config.value, "minimum_tls_version", lookup(site_config.value, "min_tls_version", "1.2"))
      remote_debugging_enabled = lookup(site_config.value, "remote_debugging_enabled", false)
      remote_debugging_version = lookup(site_config.value, "remote_debugging_version", null)
      websockets_enabled       = lookup(site_config.value, "websockets_enabled", false)

      ip_restriction              = concat(local.subnets, local.cidrs, local.service_tags)
      scm_type                    = lookup(site_config.value, "scm_type", null)
      scm_use_main_ip_restriction = var.scm_authorized_ips != [] || var.scm_authorized_subnet_ids != null ? false : true
      scm_ip_restriction          = concat(local.scm_subnets, local.scm_cidrs, local.scm_service_tags)

      dynamic "application_stack" {
        for_each = lookup(site_config.value, "application_stack", null) == null ? [] : ["application_stack"]
        content {
          dynamic "docker" {
            for_each = lookup(local.site_config.application_stack, "docker", null) == null ? [] : ["docker"]
            content {
              registry_url      = local.site_config.application_stack.docker.registry_url
              image_name        = local.site_config.application_stack.docker.image_name
              image_tag         = local.site_config.application_stack.docker.image_tag
              registry_username = lookup(local.site_config.application_stack.docker, "registry_username", null)
              registry_password = lookup(local.site_config.application_stack.docker, "registry_password", null)
            }
          }

          dotnet_version              = lookup(local.site_config.application_stack, "dotnet_version", null)
          use_dotnet_isolated_runtime = lookup(local.site_config.application_stack, "use_dotnet_isolated_runtime", null)

          java_version            = lookup(local.site_config.application_stack, "java_version", null)
          node_version            = lookup(local.site_config.application_stack, "node_version", null)
          python_version          = lookup(local.site_config.application_stack, "python_version", null)
          powershell_core_version = lookup(local.site_config.application_stack, "powershell_core_version", null)

          use_custom_runtime = lookup(local.site_config.application_stack, "use_custom_runtime", null)
        }
      }

      dynamic "cors" {
        for_each = lookup(site_config.value, "cors", []) != [] ? ["cors"] : []
        content {
          allowed_origins     = lookup(site_config.value.cors, "allowed_origins", [])
          support_credentials = lookup(site_config.value.cors, "support_credentials", false)
        }
      }
    }
  }

  https_only                 = var.https_only
  client_certificate_enabled = var.client_certificate_enabled
  client_certificate_mode    = var.client_certificate_mode
  builtin_logging_enabled    = var.builtin_logging_enabled

  lifecycle {
    ignore_changes = [
      app_settings.WEBSITE_RUN_FROM_ZIP,
      app_settings.WEBSITE_RUN_FROM_PACKAGE,
      app_settings.MACHINEKEY_DecryptionKey,
      app_settings.WEBSITE_CONTENTAZUREFILECONNECTIONSTRING,
      app_settings.WEBSITE_CONTENTSHARE
    ]
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? ["identity"] : []
    content {
      type = var.identity_type
      # Avoid perpetual changes if SystemAssigned and identity_ids is not null
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  tags = merge(var.extra_tags, var.function_app_extra_tags, local.default_tags)
}

resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  count = var.function_app_vnet_integration_enabled ? 1 : 0

  app_service_id = azurerm_linux_function_app.linux_function.id
  subnet_id      = var.function_app_vnet_integration_subnet_id
}
