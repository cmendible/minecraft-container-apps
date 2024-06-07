terraform {
  required_version = ">= 1.4.6"
  required_providers {
   azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.105.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.13.1"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}
