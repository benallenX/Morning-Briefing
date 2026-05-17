resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "!#$%*()-_=+[]{}:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_mssql_server" "main" {
  name                = "sql-${var.project_name}-8472"
  resource_group_name = azurerm_resource_group.main.name
  # SQL provisioning disabled in East US 2 for this subscription; pin to a region that allows it.
  location = "Central US"
  version  = "12.0"

  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin.result

  tags = var.tags
}

resource "azurerm_mssql_database" "main" {
  name      = "sqldb-app"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"
}

resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzure"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project_name}-8472"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Purge",
    ]
  }

  tags = var.tags
}

# Day 5: VM system-assigned identity now exists, so grant it read access
# to Key Vault secrets (least privilege: Get/List only).
resource "azurerm_key_vault_access_policy" "vm_secrets" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_virtual_machine.web_vm.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}