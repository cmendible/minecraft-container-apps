resource "azurerm_eventhub_namespace" "evh" {
  name                = local.eventhub_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "bot_commands" {
  name                = "bot-commands"
  namespace_name      = azurerm_eventhub_namespace.evh.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "consumer" {
  name                = "iot-consumer"
  namespace_name      = azurerm_eventhub_namespace.evh.name
  eventhub_name       = azurerm_eventhub.bot_commands.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_eventhub" "iot_responses" {
  name                = "iot_responses"
  namespace_name      = azurerm_eventhub_namespace.evh.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
resource "azurerm_eventhub_consumer_group" "bot" {
  name                = "minecraft-bot"
  namespace_name      = azurerm_eventhub_namespace.evh.name
  eventhub_name       = azurerm_eventhub.iot_responses.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_eventhub_namespace_authorization_rule" "auth" {
  name                = "DaprListenSend"
  namespace_name      = azurerm_eventhub_namespace.evh.name
  resource_group_name = azurerm_resource_group.rg.name

  listen = true
  send   = true
  manage = false
}

resource "azurerm_key_vault_secret" "evh_connection_string" {
  name         = "evh-connection-string"
  value        = azurerm_eventhub_namespace_authorization_rule.auth.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}
