terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "azurerm" {
  subscription_id = var.account_azure_subscription_id
  client_id = var.account_azure_client_id
  client_secret = var.account_azure_client_secret
  tenant_id = var.account_azure_tenant_id
  features {}
}