terraform {
  required_version = "~> 1.0.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.69"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.13"
    }

  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "eventrouter" {
  name     = var.eventrouter_rg
  location = var.eventrouter_location
}

resource "azurerm_storage_account" "eventrouter" {
  name                     = "${var.prefix}stevrouter"
  resource_group_name      = azurerm_resource_group.eventrouter.name
  location                 = azurerm_resource_group.eventrouter.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "eventrouter" {
  name                = "plan-eventrouter"
  location            = azurerm_resource_group.eventrouter.location
  resource_group_name = azurerm_resource_group.eventrouter.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "eventrouter" {
  name                       = "${var.prefix}-func-eventrouter"
  location                   = azurerm_resource_group.eventrouter.location
  resource_group_name        = azurerm_resource_group.eventrouter.name
  app_service_plan_id        = azurerm_app_service_plan.eventrouter.id
  storage_account_name       = azurerm_storage_account.eventrouter.name
  storage_account_access_key = azurerm_storage_account.eventrouter.primary_access_key
  os_type                    = "linux"
  version                    = "~3"
  identity {
    type = "SystemAssigned"
  }

  site_config {
    linux_fx_version = "PYTHON|3.8"
    ip_restriction = [
      {
        action                    = "Allow"
        name                      = "AllowAzureEventGrid"
        priority                  = 100
        service_tag               = "AzureEventGrid"
        virtual_network_subnet_id = null
        ip_address                = null
        headers                   = null
      }
    ]
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.appinsights_ikey
    "KEY_VAULT_NAME"                 = local.github_token_kv_name
    "EVENTROUTER_GITHUB_REPO_OWNER"  = var.github_create_issue_target.owner
    "EVENTROUTER_GITHUB_REPO_NAME"   = var.github_create_issue_target.repo
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }
}

resource "azurerm_key_vault" "github_token" {
  name                = local.github_token_kv_name
  location            = azurerm_resource_group.eventrouter.location
  resource_group_name = azurerm_resource_group.eventrouter.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_function_app.eventrouter.identity[0].principal_id

    secret_permissions = [
      "get",
      "list",
    ]
  }
}

resource "azurerm_key_vault_secret" "github_token_create_issue" {
  name         = "github-token-create-issue"
  value        = var.github_create_issue_target.token
  key_vault_id = azurerm_key_vault.github_token.id
}

provider "github" {
  token = var.github_eventrouter.token
}

data "github_actions_public_key" "az_func_eventrouter" {
  repository = var.github_eventrouter.repo
}

resource "github_actions_secret" "azure_credentials_subscription_id" {
  repository      = var.github_eventrouter.repo
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = var.azure_credentials.subscription_id
}

resource "github_actions_secret" "azure_credentials_tenant_id" {
  repository      = var.github_eventrouter.repo
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = var.azure_credentials.tenant_id
}

resource "github_actions_secret" "azure_credentials_client_id" {
  repository      = var.github_eventrouter.repo
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = var.azure_credentials.client_id
}

resource "github_actions_secret" "azure_credentials_client_secret" {
  repository      = var.github_eventrouter.repo
  secret_name     = "AZURE_CLIENT_SECRET"
  plaintext_value = var.azure_credentials.client_secret
}

resource "github_actions_secret" "azure_credentials_app_name" {
  repository      = var.github_eventrouter.repo
  secret_name     = "AZURE_FUNCTIONAPP_NAME"
  plaintext_value = azurerm_function_app.eventrouter.name
}
