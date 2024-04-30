terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.99.0"
    }
  }

}

provider "azurerm" {
  features {
    subscription {
      prevent_cancellation_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }

  # alias           = "opa"
  environment     = "usgovernment"
  subscription_id = "91da15f8-3ba9-4916-afe1-da3b8651e6d5"
  client_id       = "fcd929ad-be60-40b3-8eac-da18ce919381"
  client_secret   = "S1A1_dhn0HpDdeM0HQvk5rX1Q~T0~T.h7."
  tenant_id       = "a907e7eb-c591-42de-a930-6f76ac5fe284"

  skip_provider_registration = true
}


# provider "azurerm" {
#   features {}


#   environment     = "usgovernment"
#   # alias           = "connectivity"
#   subscription_id = "1e39e8f4-ec46-4472-947f-acd55d5742a2"


# #   skip_provider_registration = true
#  }