# UAT preparation. Corporate inputs must come from the evidence register.
module "braintrust" {
  resource_names = merge(var.resource_names, { resource_group = var.resource_group_name })
  source         = "../../modules/data-plane"

  deployment_name                  = var.deployment_name
  location                         = var.location
  existing_resource_group_name     = var.create_resource_group ? "" : var.resource_group_name
  braintrust_org_name              = var.braintrust_org_name
  brainstore_license_key           = var.brainstore_license_key
  create_brainstore_license_secret = !var.infrastructure_only
  custom_tags                      = merge(var.tags, { Environment = "UAT", ManagedBy = "Terraform" })

  existing_vnet                          = var.existing_vnet
  existing_blob_private_dns_zone_id      = var.private_dns_zone_ids.blob
  existing_postgres_private_dns_zone_id  = var.private_dns_zone_ids.postgres
  existing_redis_private_dns_zone_id     = var.private_dns_zone_ids.redis
  existing_key_vault_private_dns_zone_id = var.private_dns_zone_ids.key_vault

  create_aks_cluster                = true
  aks_private_cluster_enabled       = true
  aks_private_dns_zone_id           = var.private_dns_zone_ids.aks
  aks_network_profile               = merge(var.aks_network_profile, { outbound_type = var.aks_outbound_type })
  aks_network_role_scope_ids        = var.aks_network_role_scope_ids
  aks_identity_resource_group_roles = var.aks_identity_resource_group_roles
  aks_system_pool_vm_size           = var.node_pools.system.vm_size
  aks_system_pool_min_count         = var.node_pools.system.min_count
  aks_system_pool_max_count         = var.node_pools.system.max_count
  aks_brainstore_pool_vm_size       = var.node_pools.brainstore.vm_size
  aks_brainstore_pool_min_count     = var.node_pools.brainstore.min_count
  aks_brainstore_pool_max_count     = var.node_pools.brainstore.max_count
  aks_services_pool_vm_size         = var.node_pools.services.vm_size
  aks_services_pool_min_count       = var.node_pools.services.min_count
  aks_services_pool_max_count       = var.node_pools.services.max_count

  postgres_sku_name     = var.postgres.sku_name
  postgres_storage_mb   = var.postgres.storage_mb
  postgres_storage_tier = var.postgres.storage_tier
  postgres_version      = var.postgres.version
  redis_sku_name        = var.redis.sku_name
  redis_family          = var.redis.family
  redis_capacity        = var.redis.capacity
  redis_version         = var.redis.version

  enable_front_door        = false
  create_storage_container = true
}
