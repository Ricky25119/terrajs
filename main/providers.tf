terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.50.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
  
}

provider "azuread" {
  # Configuration is typically inherited from the environment (Azure CLI, SP credentials, etc.)
}
