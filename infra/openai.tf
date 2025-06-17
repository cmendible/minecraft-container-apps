resource "azurerm_cognitive_account" "openai" {
  name                          = var.aoai_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  location                      = "eastus"
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
}

resource "azurerm_cognitive_deployment" "gpt4_1" {
  name                 = "gpt-4.1"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.Default"
  model {
    format  = "OpenAI"
    name    = "gpt-4.1"
    version = "2025-04-14"
  }

  scale {
    type     = "GlobalStandard"
    capacity = 200
  }
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.Default"
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  scale {
    type     = "Standard"
    capacity = 40
  }
}
