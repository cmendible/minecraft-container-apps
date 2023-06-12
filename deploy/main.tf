resource "random_id" "random" {
  byte_length = 8
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

locals {
  name_sufix          = substr(lower(random_id.random.hex), 1, 4)
  resource_group_name = "${var.resource_group_name}-${local.name_sufix}"
  storage_name        = "${var.storage_name}${local.name_sufix}"
  keyvault_name       = "${var.keyvault_name}-${local.name_sufix}"
  cosmosdb_name       = "${var.cosmos_name}-${local.name_sufix}"
  eventhub_name       = "${var.eventhub_name}-${local.name_sufix}"
  cae_name            = "${var.cae_name}-${local.name_sufix}"
  logws_name          = "${var.logws_name}-${local.name_sufix}"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}
