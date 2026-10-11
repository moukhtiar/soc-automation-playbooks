# STATUS: reference only, NOT YET APPLIED. The validated build in this repo was done in the Azure portal.
# Check resource arguments (especially the automation rule `condition` blocks) against your azurerm version.
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "azurerm" {
  features {}
}
