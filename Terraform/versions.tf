terraform {
  required_version = ">= 1.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.20"
    }
  }
}

