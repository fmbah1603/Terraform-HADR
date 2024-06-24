resource "azurerm_resource_group" "resourcegroupA" {
  name     = var.resource_group_name[0]
  location = var.location[0]
}
resource "azurerm_resource_group" "resourcegroupB" {
  name     = var.resource_group_name[1]
  location = var.location[1]
}

# Creating a virtual network
data "azurerm_virtual_network" "vnetA" {
  name                = var.virtual_network_name[0]
  resource_group_name = var.resource_group_name[2]
  # location            = "East US"
}

data "azurerm_virtual_network" "vnetB" {
  name                = var.virtual_network_name[1]
  resource_group_name = var.resource_group_name[3]
  # location            = "West US"
}

# Creating a subnet
data "azurerm_subnet" "subnetA" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name[2]
  virtual_network_name = var.virtual_network_name[0]
}

data "azurerm_subnet" "subnetB" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name[3]
  virtual_network_name = var.virtual_network_name[1]
}

# Creating network interface 
resource "azurerm_network_interface" "nicA" {
  name                = "az-hadr-usaz-dev-vm0001-nic"
  location            = var.location[0]
  resource_group_name = var.resource_group_name[0]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_resource_group.resourcegroupA]
}
resource "azurerm_network_interface" "nicB" {
  name                = "az-hadr-usva-dev-vm0002-nic"
  location            = var.location[1]
  resource_group_name = var.resource_group_name[1]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnetB.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_resource_group.resourcegroupB]
}

resource "azurerm_virtual_machine" "virtual_machineA" {
  name                  = var.virtual_machine_name[0]
  resource_group_name   = var.resource_group_name[0]
  location              = var.location[0]
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.nicA.id]
  os_profile {
    admin_username = var.virtual_machine_username
    admin_password = var.virtual_machine_password
    computer_name  = "hadradmin"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  availability_set_id = azurerm_availability_set.availability_setA.id
  storage_os_disk {
    name              = "hadr-os-disk"
    os_type           = "Linux"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  depends_on = [azurerm_network_interface.nicA]
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# resource "azurerm_virtual_machine" "virtual_machineB" {
#   name                            = var.virtual_machine_name[1]
#   resource_group_name             = var.resource_group_name[1]
#   location                        = var.location[1]
#   vm_size                            = "Standard_DS1_v2"
#   network_interface_ids           = [azurerm_network_interface.nicB.id]
#   os_profile {
#   admin_username                  = var.virtual_machine_username
#   admin_password                  = var.virtual_machine_password
#   computer_name =  "hadradmin"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }
#   availability_set_id             = azurerm_availability_set.availability_setB.id
#   storage_os_disk {
#     name = "hadr-os-disk"
#     os_type = "Linux"
#     caching              = "ReadWrite"
#     create_option = "FromImage"
#     managed_disk_type = "Premium_LRS"
#   }
#   depends_on = [azurerm_network_interface.nicB]
#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
# }

resource "azurerm_windows_virtual_machine" "virtual_machineB" {
  name                  = var.virtual_machine_name[1]
  resource_group_name   = var.resource_group_name[1]
  location              = var.location[1]
  size                  = "Standard_DS1_v2"
  admin_username        = var.virtual_machine_username
  admin_password        = var.virtual_machine_password
  network_interface_ids = [azurerm_network_interface.nicB.id]
  provision_vm_agent    = true
  availability_set_id   = azurerm_availability_set.availability_setB.id
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  depends_on = [azurerm_network_interface.nicB]
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_recovery_services_vault" "vaultA" {
  name                = "az-hadr-dev-usaz-rsv"
  location            = var.location[0]
  resource_group_name = var.resource_group_name[0]
  sku                 = "Standard"

  soft_delete_enabled = false
}
# Creating a backup policy
resource "azurerm_backup_protected_vm" "backup_policyA" {
  resource_group_name = var.resource_group_name[0]
  recovery_vault_name = azurerm_recovery_services_vault.vaultA.name
  source_vm_id        = azurerm_virtual_machine.virtual_machineA.id
  backup_policy_id    = azurerm_backup_policy_vm.policyA.id
  depends_on          = [azurerm_resource_group.resourcegroupA]
}

resource "azurerm_availability_set" "availability_setA" {
  name                = "my-availability-set"
  resource_group_name = var.resource_group_name[0]
  location            = var.location[0]
  managed             = true

  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  depends_on                   = [azurerm_resource_group.resourcegroupA]
}

resource "azurerm_availability_set" "availability_setB" {
  name                = "my-availability-set"
  resource_group_name = var.resource_group_name[1]
  location            = var.location[1]
  managed             = true

  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  depends_on                   = [azurerm_resource_group.resourcegroupB]
}

# Associate the Virtual Machine with the Availability Set
# resource "azurerm_virtual_machine_extension" "site_extensionA" {
#   name                 = "vmextension"
#   virtual_machine_id   = azurerm_linux_virtual_machine.virtual_machineA.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = jsonencode({
#     "commandToExecute" = "echo 'Hello, World!' > ~/hello.txt"
#   })
# }
# Associate the Virtual Machine with the Availability Set
# resource "azurerm_virtual_machine_extension" "siteextensionB" {
#   name                 = "vmextension"
#   virtual_machine_id   = azurerm_windows_virtual_machine.virtual_machineB.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = jsonencode({
#     "commandToExecute" = "echo 'Hello, World!' > ~/hello.txt"
#   })
# }
# Creating a backup protected VM
resource "azurerm_backup_policy_vm" "policyA" {
  name                = "az-hadr-dev-usaz-policy001"
  resource_group_name = var.resource_group_name[0]
  recovery_vault_name = azurerm_recovery_services_vault.vaultA.name
  timezone            = "Eastern Standard Time"
  depends_on          = [azurerm_resource_group.resourcegroupA, azurerm_recovery_services_vault.vaultA]
  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }
}


resource "azurerm_recovery_services_vault" "vaultB" {
  name                = "az-hadr-dev-usva-rsv"
  location            = var.location[1]
  resource_group_name = var.resource_group_name[1]
  sku                 = "Standard"

  soft_delete_enabled = false
}
# Creating a backup policy
resource "azurerm_backup_protected_vm" "backup_policyB" {
  resource_group_name = var.resource_group_name[1]
  recovery_vault_name = azurerm_recovery_services_vault.vaultB.name
  source_vm_id        = azurerm_windows_virtual_machine.virtual_machineB.id
  backup_policy_id    = azurerm_backup_policy_vm.policyB.id
  depends_on          = [azurerm_resource_group.resourcegroupB]
}

# Creating a backup protected VM
resource "azurerm_backup_policy_vm" "policyB" {
  name                = "az-hadr-dev-usva-policy002"
  resource_group_name = var.resource_group_name[1]
  recovery_vault_name = azurerm_recovery_services_vault.vaultB.name
  timezone            = "Eastern Standard Time"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }
  depends_on = [azurerm_resource_group.resourcegroupB, azurerm_recovery_services_vault.vaultB]
}
resource "azurerm_storage_account" "storageaccountA" {
  name                     = "hadruscourtsstorageacc"
  resource_group_name      = var.resource_group_name[0]
  location                 = var.location[0]
  account_tier             = "Standard"
  account_replication_type = "GRS"
  depends_on               = [azurerm_resource_group.resourcegroupA]
}

# App Service Plan 1
resource "azurerm_app_service_plan" "hadr_serviceplanA" {
  name                = "hadr001-App-plan-az"
  location            = var.location[0] # Update with your desired location for the first App Service Plan
  resource_group_name = var.resource_group_name[0]
  kind                = "Windows"
  reserved            = false
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# App Service 1
resource "azurerm_app_service" "hadr_appserviceA" {
  name                = "hadr-appservice-az"
  location            = var.location[0] # Update with your desired location for the first App Service
  resource_group_name = var.resource_group_name[0]
  app_service_plan_id = azurerm_app_service_plan.hadr_serviceplanA.id
}

# App Service Plan 2
resource "azurerm_app_service_plan" "hadr_serviceplanB" {
  name                = "hadr002-App-plan-va"
  location            = var.location[1] # Update with your desired location for the second App Service Plan
  resource_group_name = var.resource_group_name[1]
  kind                = "Windows"
  reserved            = false
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# App Service 2
resource "azurerm_app_service" "hadr_appserviceB" {
  name                = "hadr-appservice-va"
  location            = var.location[1] # Update with your desired location for the second App Service
  resource_group_name = var.resource_group_name[1]
  app_service_plan_id = azurerm_app_service_plan.hadr_serviceplanB.id
}

# # SQL IaaS server
# resource "azurerm_sql_server" "hadr_sqlserver" {
#   name                         = "hadr001-hadr-az"
#   resource_group_name          = var.resource_group_name[0]
#   location                     = var.location[0]  # Update with your desired location for the SQL IaaS server
#   version                      = "12.0"  # Update with your desired SQL Server version
#   administrator_login          = "sqladmin"  # Update with your desired SQL administrator login
#   administrator_login_password = "Password123!"  # Update with your desired SQL administrator password
# }

# # Recovery Services Vault Backup Policy
# resource "azurerm_recovery_services_vault_backup_policy_association" "hadr_backup_sql" {
#   recovery_services_vault_name = azurerm_recovery_services_vault.vaultA.name  # Update with your existing Recovery Services Vault name
#   resource_group_name          = var.resource_group_name[0]
#   policy_id                    = azurerm_backup_policy_vm.policyA.id  # Update with the ID of your existing backup policy
#   type                         = "SQL"  # Type of the resource to associate with the backup policy, in this case, SQL
#   source_resource_id           = azurerm_sql_server.hadr_sqlserver.id
# }

# Azure Traffic Manager
resource "azurerm_traffic_manager_profile" "hadr_traffic_profileA" {
  name                   = "hadr001-traffic-profile-az"
  resource_group_name    = var.resource_group_name[0]
  profile_status         = "Enabled"
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "uscourtshadr01"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  # # Endpoint for the first App Service
  # # Priority 1
  # endpoint {
  #   name                = "appservice1-endpoint"
  #   target_resource_id  = azurerm_app_service.hadr_appserviceA.id
  #   type                = "AzureEndpoints"
  #   priority            = 1
  # }

  # # Endpoint for the second App Service
  # # Priority 2
  # endpoint {
  #   name                = "appservice2-endpoint"
  #   target_resource_id  = azurerm_app_service.hadr_appserviceB.id
  #   type                = "AzureEndpoints"
  #   priority            = 2
  # }
}

resource "azurerm_traffic_manager_azure_endpoint" "hadr_tmendpointA" {
  name               = "hadr001-tm-endpoint"
  profile_id         = azurerm_traffic_manager_profile.hadr_traffic_profileA.id
  target_resource_id = azurerm_app_service.hadr_appserviceA.id
  weight             = 100
}
resource "azurerm_traffic_manager_azure_endpoint" "hadr_tmendpointB" {
  name               = "hadr002-tm-endpoint"
  profile_id         = azurerm_traffic_manager_profile.hadr_traffic_profileA.id
  target_resource_id = azurerm_app_service.hadr_appserviceB.id
  weight             = 200
}
# resource "azurerm_traffic_manager_azure_endpoint" "example" {
#   name                 = "example-endpoint"
#   profile_id           = azurerm_traffic_manager_profile.example.id
#   always_serve_enabled = true
#   weight               = 100
#   target_resource_id   = azurerm_public_ip.example.id
# }
# output "os_disk_properties" {
#   value = azurerm_virtual_machine.virtual_machineA.os_disk
# }
resource "azurerm_site_recovery_fabric" "primary" {
  name                = "hadr-primary-fabric"
  resource_group_name = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name = azurerm_recovery_services_vault.vaultB.name
  location            = var.location[0]
}

resource "azurerm_site_recovery_fabric" "secondary" {
  name                = "hadr-secondary-fabric"
  resource_group_name = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name = azurerm_recovery_services_vault.vaultB.name
  location            = var.location[1]
}

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "hadr-primary-protection-container"
  resource_group_name  = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name  = azurerm_recovery_services_vault.vaultB.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  name                 = "hadr-secondary-protection-container"
  resource_group_name  = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name  = azurerm_recovery_services_vault.vaultB.name
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
}

resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = "hadr-policy"
  resource_group_name                                  = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name                                  = azurerm_recovery_services_vault.vaultB.name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 12 * 60
}

resource "azurerm_site_recovery_protection_container_mapping" "container-mapping" {
  name                                      = "hadr-container-mapping"
  resource_group_name                       = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name                       = azurerm_recovery_services_vault.vaultB.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
}

resource "azurerm_site_recovery_network_mapping" "network-mapping" {
  name                        = "hadr-network-mapping"
  resource_group_name         = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name         = azurerm_recovery_services_vault.vaultB.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
  source_network_id           = data.azurerm_virtual_network.vnetA.id
  target_network_id           = data.azurerm_virtual_network.vnetB.id
}


# resource "azurerm_public_ip" "primary" {
#   name                = "vm-public-ip-primary"
#   allocation_method   = "Static"
#   location            = azurerm_resource_group.primary.location
#   resource_group_name = azurerm_resource_group.primary.name
#   sku                 = "Basic"
# }

# resource "azurerm_public_ip" "secondary" {
#   name                = "vm-public-ip-secondary"
#   allocation_method   = "Static"
#   location            = azurerm_resource_group.secondary.location
#   resource_group_name = azurerm_resource_group.secondary.name
#   sku                 = "Basic"
# }

resource "azurerm_network_interface" "vm" {
  name                = "hadr-vm-nic"
  location            = var.location[0]
  resource_group_name = azurerm_resource_group.resourcegroupA.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_site_recovery_replicated_vm" "vm-replication" {
  name                                      = "vm-replication"
  resource_group_name                       = azurerm_resource_group.resourcegroupB.name
  recovery_vault_name                       = azurerm_recovery_services_vault.vaultB.name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.name
  source_vm_id                              = azurerm_virtual_machine.virtual_machineA.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name

  target_resource_group_id                = azurerm_resource_group.resourcegroupB.id
  target_recovery_fabric_id               = azurerm_site_recovery_fabric.secondary.id
  target_recovery_protection_container_id = azurerm_site_recovery_protection_container.secondary.id

  managed_disk {
    disk_id                    = azurerm_virtual_machine.virtual_machineA.storage_os_disk[0].managed_disk_id
    staging_storage_account_id = azurerm_storage_account.storageaccountA.id
    target_resource_group_id   = azurerm_resource_group.resourcegroupB.id
    target_disk_type           = "Premium_LRS"
    target_replica_disk_type   = "Premium_LRS"
  }

  network_interface {
    source_network_interface_id = azurerm_network_interface.nicA.id
    target_subnet_name          = data.azurerm_subnet.subnetA.name
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.container-mapping,
    azurerm_site_recovery_network_mapping.network-mapping,
  ]
}

resource "azurerm_site_recovery_replication_recovery_plan" "hadrrecoveryrep" {
  name                      = "hadr-recovery-plan"
  recovery_vault_id         = azurerm_recovery_services_vault.vaultB.id
  source_recovery_fabric_id = azurerm_site_recovery_fabric.primary.id
  target_recovery_fabric_id = azurerm_site_recovery_fabric.secondary.id

  shutdown_recovery_group {}

  failover_recovery_group {}

  boot_recovery_group {
    replicated_protected_items = [azurerm_site_recovery_replicated_vm.vm-replication.id]
  }

}

# # Create Azure SQL Server
# resource "azurerm_sql_server" "sql-serverA" {
#   name                         = "hadr-sql-prim-server"
#   resource_group_name          = var.resource_group_name[0]
#   location                     = var.location[0]  # Update with your desired location
#   version                      = "12.0"
#   administrator_login          = "sqladmin"
#   administrator_login_password = "P@ssw0rd123!"  # Update with your desired password
# }
# # Create Azure SQL Server
# resource "azurerm_sql_server" "sql-serverB" {
#   name                         = "hadr-sql-sec-server"
#   resource_group_name          = var.resource_group_name[1]
#   location                     = var.location[1]  # Update with your desired location
#   version                      = "12.0"
#   administrator_login          = "sqladmin"
#   administrator_login_password = "P@ssw0rd123!"  # Update with your desired password
# }

# # Create Primary Azure SQL Database
# resource "azurerm_sql_database" "primary" {
#   name                = "hadr-sql-db-primary"
#   resource_group_name = var.resource_group_name[0]
#   location            = var.location[0]  # Update with your desired location
#   server_name         = azurerm_sql_server.sql-serverA.name
#   edition             = "Standard"
#   collation           = "SQL_Latin1_General_CP1_CI_AS"
#   # sku_name            = "S0"
#   depends_on = [ azurerm_sql_server.sql-serverA ]
# }

# # # Create Secondary Azure SQL Database
# # resource "azurerm_sql_database" "secondary" {
# #   name                = "hadr-sql-db-secondary"
# #   resource_group_name = var.resource_group_name[0]
# #   location            = var.location[1]  # Update with your desired secondary region
# #   server_name         = azurerm_sql_server.sql-serverB.name
# #   edition             = "Standard"
# #   collation           = "SQL_Latin1_General_CP1_CI_AS"
# #   # sku_name            = "S0"
# #   depends_on = [ azurerm_sql_server.sql_server.sql-serverB ]
# # }

# # # Enable Geo-Replication for Azure SQL Database
# # resource "azurerm_sql_database_replication_link" "hadr_rep_link" {
# #   name                                 = "hadr-replication-link"
# #   resource_group_name                  = var.resource_group_name[0]
# #   server_name                          = azurerm_sql_server.sql-serverA.name
# #   database_name                        = azurerm_sql_database.primary.name
# #   partner_server_resource_id           = azurerm_sql_server.sql-serverB.id
# #   partner_database_name                = azurerm_sql_database.secondary.name
# #   ignore_replication_differences       = false
# #   is_to_be_cutover                     = false
# # }

# # Create Failover Group for Azure SQL Database
# resource "azurerm_sql_failover_group" "hadr-failovergroup" {
#   name                                  = "hadr-failover-group"
#   resource_group_name                   = var.resource_group_name[0]
#   server_name                           = azurerm_sql_server.sql-serverA.name
#   databases                             = [azurerm_sql_database.primary.id]
#   partner_servers {
#     id = azurerm_sql_server.sql-serverB.id
#   }
#   read_write_endpoint_failover_policy {
#     mode          = "Automatic"
#     grace_minutes = 60
#   }  
# }
