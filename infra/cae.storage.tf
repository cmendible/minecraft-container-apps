resource "azurerm_storage_account" "st" {
  name                            = local.storage_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_share" "share" {
  name                 = "minecraft"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 5
}

resource "azurerm_storage_share_file" "ops" {
  name             = "ops.json"
  storage_share_id = azurerm_storage_share.share.id
  source           = "./ops.json"
}

resource "azurerm_storage_container" "container" {
  name                 = "subscribers"
  storage_account_name = azurerm_storage_account.st.name
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.st.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "storage_account_connection_string" {
  name         = "storage-account-connection-string"
  value        = azurerm_storage_account.st.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_container_app_environment_storage" "data" {
  name                         = "minecraftstorage"
  container_app_environment_id = azapi_resource.cae.id
  account_name                 = azurerm_storage_account.st.name
  share_name                   = azurerm_storage_share.share.name
  access_key                   = azurerm_storage_account.st.primary_access_key
  access_mode                  = "ReadWrite"
}