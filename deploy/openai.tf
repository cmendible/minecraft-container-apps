resource "azurerm_cognitive_account" "openai" {
  name                          = var.aoai_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  location                      = "eastus"
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
}

resource "azurerm_cognitive_deployment" "gpt_35_turbo" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0301"
  }

  scale {
    type = "Standard"
  }
}
