# Deploy Key Vault
resource "azurerm_key_vault" "kv" {
  name                = local.keyvault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_subscription.current.tenant_id

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = []

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]

    storage_permissions = []
  }

  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = azurerm_user_assigned_identity.mi.principal_id

    key_permissions = []

    secret_permissions = [
      "Get",
      "List"
    ]

    storage_permissions = []
  }
}
