terraform {
  backend "azurerm" {
    config = {
      organization = "AOUSC"
    }
    environment          = "usgovernment"
    subscription_id      = "b1d5f237-b1f4-42f1-a4b7-53c59d6bd99d"
    resource_group_name  = "az-mgmt-usva-tf-rg"
    storage_account_name = "azmgmtusvaterraformsa"
    container_name       = "terraform"
    key                  = "hadr.terraform.tfstate"

  }
}

#  terraform {
#   backend "azurerm" {
#     resource_group_name  = "myResourceGroup"
#     storage_account_name = "mystorageaccount"
#     container_name       = "tfstate"
#     key                  = "terraform.tfstate"
#   }