variable "subscription_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "Provide the verified PROD subscription UUID."
  }
}
variable "tenant_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "Provide the verified tenant UUID."
  }
}
variable "resource_group_name" {
  type = string
  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "An existing dedicated workload resource group is required."
  }
}
variable "deployment_name" { type = string }
variable "location" { type = string }
variable "infrastructure_only" {
  description = "Prepare Azure infrastructure without vendor organization/license inputs. Does not install or enable Braintrust; complete application configuration separately."
  type        = bool
  default     = false
}

variable "braintrust_org_name" {
  type    = string
  default = ""
  validation {
    condition     = var.infrastructure_only || length(trimspace(var.braintrust_org_name)) > 0
    error_message = "Provide the confirmed Braintrust organization name."
  }
}
variable "brainstore_license_key" {
  type      = string
  sensitive = true
  default   = ""
  validation {
    condition     = var.infrastructure_only || length(trimspace(var.brainstore_license_key)) > 0
    error_message = "Supply the license through the approved secret mechanism, never a committed tfvars file."
  }
}
variable "tags" {
  type = map(string)
}
variable "existing_vnet" {
  type = object({
    id                                         = string
    name                                       = string
    services_subnet_id                         = string
    private_endpoint_subnet_id                 = string
    private_endpoint_network_security_group_id = string
    address_space                              = string # Legacy first prefix, metadata only
    address_spaces                             = optional(list(string), [])
  })
  validation {
    condition     = can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.existing_vnet.id)) && startswith(lower(var.existing_vnet.services_subnet_id), "${lower(var.existing_vnet.id)}/subnets/") && startswith(lower(var.existing_vnet.private_endpoint_subnet_id), "${lower(var.existing_vnet.id)}/subnets/") && lower(var.existing_vnet.services_subnet_id) != lower(var.existing_vnet.private_endpoint_subnet_id)
    error_message = "Provide the verified VNet ID and two distinct subnets belonging to it."
  }
}
variable "private_dns_zone_ids" {
  type = object({ aks = string, blob = string, postgres = string, redis = string, key_vault = string })
  validation {
    condition     = alltrue([for service, id in var.private_dns_zone_ids : (service == "aks" && id == "System") || can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/[^/]+$", id))])
    error_message = "Supply approved DNS zone IDs; AKS alone may use System following the GPS pattern; corporate resolution still requires deployment testing."
  }
}
variable "aks_outbound_type" {
  description = "Reviewed egress design. GPS uses loadBalancer with secured vWAN; that is not proof of effective routing for this workload. UDR requires its subnet route prerequisites. No routes are created here."
  type        = string
  validation {
    condition     = contains(["userDefinedRouting", "loadBalancer"], var.aks_outbound_type)
    error_message = "Select a reviewed UDR or loadBalancer egress profile; do not infer firewall enforcement from this value alone."
  }
}
variable "aks_network_profile" {
  type = object({
    network_plugin      = string
    network_plugin_mode = optional(string)
    pod_cidr            = optional(string)
    service_cidr        = string
    dns_service_ip      = string
  })
  validation {
    condition     = contains(["azure", "kubenet"], var.aks_network_profile.network_plugin) && can(cidrhost(var.aks_network_profile.service_cidr, 0)) && can(cidrhost("${var.aks_network_profile.dns_service_ip}/32", 0))
    error_message = "Use an approved AKS network plugin, service CIDR and DNS IP. CIDR overlap and mode compatibility must be reviewed."
  }
}
variable "aks_network_role_scope_ids" {
  description = "Approved Network Contributor scopes for the AKS identity (VNet/subnet/route table as required by the chosen topology)."
  type        = set(string)
  validation {
    condition     = length(var.aks_network_role_scope_ids) > 0 && alltrue([for id in var.aks_network_role_scope_ids : startswith(lower(id), "/subscriptions/")])
    error_message = "Provide reviewed network resource scopes; they are not inferred from a label or a CIDR."
  }
}
variable "aks_identity_resource_group_roles" {
  description = "Explicitly reviewed RG roles for the AKS identity. No broad upstream defaults are inherited; use an empty set if no RG role is required."
  type        = set(string)
}
variable "node_pools" {
  type = object({
    system     = object({ vm_size = string, min_count = number, max_count = number })
    brainstore = object({ vm_size = string, min_count = number, max_count = number })
    services   = object({ vm_size = string, min_count = number, max_count = number })
  })
  validation {
    condition     = alltrue([for pool in values(var.node_pools) : try(length(trimspace(pool.vm_size)) > 0 && pool.min_count >= 1 && pool.max_count >= pool.min_count && floor(pool.min_count) == pool.min_count && floor(pool.max_count) == pool.max_count, false)])
    error_message = "Every pool requires an approved VM size and positive integer min/max counts."
  }
}
variable "postgres" {
  type = object({ sku_name = string, storage_mb = number, storage_tier = string, version = string })
  validation {
    condition     = try(var.postgres.storage_mb > 0 && length(var.postgres.sku_name) > 0 && length(var.postgres.storage_tier) > 0 && tonumber(var.postgres.version) >= 15, false)
    error_message = "Supply a supported PostgreSQL 15+ profile confirmed with Braintrust."
  }
}
variable "redis" {
  description = "Vendor-supported Azure Cache for Redis profile must be confirmed; do not copy the upstream Redis 6 default."
  type        = object({ sku_name = string, family = string, capacity = number, version = string })
  validation {
    condition     = try(var.redis.capacity > 0 && length(var.redis.sku_name) > 0 && length(var.redis.family) > 0 && length(var.redis.version) > 0, false)
    error_message = "Provide an explicit vendor-supported Redis profile; version/service support remains an open item."
  }
}

variable "resource_names" {
  description = "Explicit Azure names. Empty map preserves vendor naming; changing existing names can force replacement."
  type        = map(string)
  validation {
    condition     = alltrue([for k, v in var.resource_names : contains(["resource_group", "aks", "aks_identity", "app_identity", "key_vault", "key_vault_pe", "key_vault_asg", "postgres", "postgres_pe", "postgres_asg", "postgres_identity", "redis", "redis_pe", "redis_asg", "storage", "storage_pe", "storage_identity"], k) && length(trimspace(v)) > 0])
    error_message = "Use supported resource name keys and nonempty values."
  }
}

variable "create_resource_group" {
  description = "Create a new workload RG instead of looking up the existing one. Does not move or remove the old RG."
  type        = bool
  default     = false
}
