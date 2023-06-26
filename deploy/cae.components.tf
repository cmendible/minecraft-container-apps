resource "azurerm_container_app_environment_dapr_component" "secret" {
  name                         = "secretstore"
  container_app_environment_id = azapi_resource.cae.id
  component_type               = "secretstores.azure.keyvault"
  version                      = "v1"

  metadata {
    name  = "vaultName"
    value = azurerm_key_vault.kv.name
  }

  metadata {
    name  = "azureEnvironment"
    value = "AZUREPUBLICCLOUD"
  }

  metadata {
    name  = "azureClientId"
    value = azurerm_user_assigned_identity.mi.client_id
  }
}

resource "azapi_resource" "state" {
  name      = "statedb"
  parent_id = azapi_resource.cae.id
  type      = "Microsoft.App/managedEnvironments/daprComponents@2022-11-01-preview"

  body = jsonencode({
    properties : {
      componentType        = "state.azure.cosmosdb"
      version              = "v1"
      secretStoreComponent = "${azurerm_container_app_environment_dapr_component.secret.name}"
      secrets              = []
      metadata = [
        {
          name  = "url"
          value = "${azurerm_cosmosdb_account.db.endpoint}"
        },
        {
          name  = "database"
          value = "${azurerm_cosmosdb_sql_database.db.name}"
        },
        {
          name  = "collection"
          value = "state"
        },
        {
          name      = "masterKey"
          secretRef = "cosmosdb-master-key"
        },
        {
          name  = "actorStateStore"
          value = "true"
        }
      ]
    }
  })
}

resource "azapi_resource" "messagebus" {
  name      = "messagebus"
  parent_id = azapi_resource.cae.id
  type      = "Microsoft.App/managedEnvironments/daprComponents@2022-11-01-preview"

  body = jsonencode({
    properties : {
      componentType        = "pubsub.azure.eventhubs"
      version              = "v1"
      secretStoreComponent = "${azurerm_container_app_environment_dapr_component.secret.name}"
      secrets              = []
      metadata = [
        {
          name  = "enableEntityManagement"
          value = "false"
        },
        {
          name  = "storageAccountName"
          value = "${azurerm_storage_account.st.name}"
        },
        {
          name  = "storageContainerName"
          value = "subscribers"
        },
        {
          name      = "storageAccountKey"
          secretRef = "storage-account-key"
        },
        {
          name      = "connectionString"
          secretRef = "evh-connection-string"
        }
      ]
    }
  })
}
