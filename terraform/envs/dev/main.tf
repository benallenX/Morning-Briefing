terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
  tags     = var.tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}8472"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }

  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.main.id
}