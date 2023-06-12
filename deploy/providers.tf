terraform {
  required_version = ">= 1.4.6"
  required_providers {
    azurerm = {
      version = ">= 3.59.0"
    }
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
