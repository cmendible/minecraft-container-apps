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

  backend "azurerm" {
    resource_group_name  = "terraform-stuff"
    storage_account_name = "myiacstates"
    container_name       = "tfstate"
    key                  = "minecraft-demo.tfstate"
    
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
