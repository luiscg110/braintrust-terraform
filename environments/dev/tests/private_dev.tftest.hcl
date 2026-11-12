# All identifiers and values below are synthetic fixtures, not approved resources or credentials.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "000"
      subscription_id = "000"
      object_id       = "000"
      client_id       = "000"
    }
  }
  mock_data "azurerm_resource_group" {
    defaults = { id = "/subscriptions/000/resourceGroups/test-workload" }
  }
}
mock_provider "random" {}

variables {
  subscription_id        = "000"
  tenant_id              = "000"
  resource_group_name    = "test-workload"
  deployment_name        = "bt-test-dev"
  location               = "eastus2"
  braintrust_org_name    = "synthetic-test-org"
  brainstore_license_key = "000"
  tags                   = { Purpose = "offline-test" }
  existing_vnet = {
    id                                         = "/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet"
    name                                       = "test-vnet"
    services_subnet_id                         = "/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/aks"
    private_endpoint_subnet_id                 = "/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/pe"
    private_endpoint_network_security_group_id = ""
    address_space                              = "000"
    address_spaces                             = ["000", "000"]
  }
  private_dns_zone_ids = {
    aks       = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.eastus2.azmk8s.io"
    blob      = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    key_vault = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    postgres  = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
    redis     = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.redis.cache.windows.net"
  }
  aks_network_profile               = { network_plugin = "azure", network_plugin_mode = "overlay", pod_cidr = "000", service_cidr = "000", dns_service_ip = "000" }
  aks_network_role_scope_ids        = ["/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet"]
  aks_identity_resource_group_roles = []
  node_pools = {
    system     = { vm_size = "Standard_D2as_v6", min_count = 2, max_count = 3 }
    brainstore = { vm_size = "Standard_D32ds_v6", min_count = 1, max_count = 2 }
    services   = { vm_size = "Standard_D16s_v6", min_count = 1, max_count = 2 }
  }
  postgres = { sku_name = "MO_Standard_E2ds_v5", storage_mb = 131072, storage_tier = "P20", version = "15" }
  redis    = { sku_name = "Standard", family = "C", capacity = 1, version = "6" }
}

run "private_dev_configuration" {
  command = plan
  assert {
    condition     = output.main_vnet_address_spaces == tolist(["000", "000"])
    error_message = "Preserve every existing VNet prefix without allocating or changing the VNet."
  }
  assert {
    condition     = output.ea_configuration.front_door_instances == 0 && output.ea_configuration.new_vnet_instances == 0
    error_message = "DEV must reuse the approved VNet and must not instantiate Front Door."
  }
  assert {
    condition     = output.ea_configuration.storage_public_access == false && output.ea_configuration.key_vault_public_access == false
    error_message = "Storage and the new Key Vault must disable public network access."
  }
  assert {
    condition     = output.ea_configuration.aks.private_cluster_enabled && !output.ea_configuration.aks.public_fqdn_enabled && output.ea_configuration.aks.outbound_type == "userDefinedRouting"
    error_message = "AKS must be private, omit public FQDN and request UDR egress."
  }
  assert {
    condition     = output.ea_configuration.aks.private_dns_zone_id == var.private_dns_zone_ids.aks && contains(output.ea_configuration.storage_dns_zone_ids, var.private_dns_zone_ids.blob) && contains(output.ea_configuration.key_vault_dns_zone_ids, var.private_dns_zone_ids.key_vault)
    error_message = "The selected approved DNS IDs must reach AKS and the private endpoint DNS groups."
  }
  assert {
    condition     = length(output.ea_configuration.aks.resource_group_roles) == 0 && toset(output.ea_configuration.aks.network_role_scopes) == var.aks_network_role_scope_ids
    error_message = "DEV must use explicit identity scopes rather than inheriting upstream RG-wide roles."
  }
}

run "reject_missing_dns" {
  command = plan
  variables { private_dns_zone_ids = { aks = "", blob = "", postgres = "", redis = "", key_vault = "" } }
  expect_failures = [var.private_dns_zone_ids]
}
run "private_system_dns_and_explicit_lb_profile" {
  command = plan
  variables {
    aks_outbound_type = "loadBalancer"
    private_dns_zone_ids = {
      aks       = "System"
      blob      = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      key_vault = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      postgres  = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
      redis     = "/subscriptions/000/resourceGroups/test-dns/providers/Microsoft.Network/privateDnsZones/privatelink.redis.cache.windows.net"
    }
  }
  assert {
    condition     = output.ea_configuration.aks.private_cluster_enabled && !output.ea_configuration.aks.public_fqdn_enabled && output.ea_configuration.aks.private_dns_zone_id == "System" && output.ea_configuration.aks.outbound_type == "loadBalancer"
    error_message = "Explicit LB egress/System DNS must preserve a private API without public FQDN. This mock does not validate hub routing."
  }
}
run "reject_same_subnet" {
  command = plan
  variables {
    existing_vnet = {
      id                                         = "/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet"
      name                                       = "test-vnet"
      services_subnet_id                         = "/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/same"
      private_endpoint_subnet_id                 = "/subscriptions/000/resourceGroups/test-network/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/same"
      private_endpoint_network_security_group_id = ""
      address_space                              = "000"
    }
  }
  expect_failures = [var.existing_vnet]
}

run "infrastructure_only_without_vendor_inputs" {
  command = plan
  variables {
    infrastructure_only    = true
    braintrust_org_name    = ""
    brainstore_license_key = ""
  }
  assert {
    condition     = output.ea_configuration.brainstore_license_secret_instances == 0 && output.ea_configuration.front_door_instances == 0 && output.ea_configuration.aks.private_cluster_enabled
    error_message = "Infrastructure-only mode must omit the license secret while keeping AKS private and Front Door disabled."
  }
}
run "application_configuration_requires_vendor_license" {
  command = plan
  variables {
    infrastructure_only    = false
    brainstore_license_key = ""
  }
  expect_failures = [var.brainstore_license_key]
}

run "explicit_environment_names_new_workload_group" {
  command = plan
  variables {
    create_resource_group = true
    resource_group_name   = "000-000-braintrust-dev-eus2"
    resource_names = {
      aks       = "000ai-braintrust-dev-eus2"
      key_vault = "kv-000-bt-dev-eus2"
      storage   = "000deveus2"
    }
  }
  assert {
    condition     = output.resource_group_name == "000-000-braintrust-dev-eus2" && output.aks_cluster_name == "000ai-braintrust-dev-eus2" && output.helm_object_storage_values.storageAccountName == "000deveus2"
    error_message = "Explicit resource names must reach the actual RG/AKS/Storage resources and downstream Helm values."
  }
  assert {
    condition     = output.helm_object_storage_values.brainstoreContainer == "brainstore" && output.helm_object_storage_values.responseContainer == "responses" && output.helm_object_storage_values.codeBundleContainer == "code-bundles"
    error_message = "Azure naming must not alter the vendor container contract."
  }
}
run "reject_misspelled_resource_name" {
  command = plan
  variables { resource_names = { storag = "000deveus2" } }
  expect_failures = [var.resource_names]
}
