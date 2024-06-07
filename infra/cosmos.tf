resource "azurerm_cosmosdb_account" "db" {
  name                          = local.cosmosdb_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = true

  consistency_policy {
    consistency_level = "Eventual"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "minecraft"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                  = "state"
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.db.name
  partition_key_path    = "/partitionKey"
  partition_key_version = 1
  throughput            = 400
}

resource "azurerm_key_vault_secret" "cosmosdb_master_key" {
  name         = "cosmosdb-master-key"
  value        = azurerm_cosmosdb_account.db.primary_key
  key_vault_id = azurerm_key_vault.kv.id
}
