provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  # Registration is owned by the approved platform team, not an implicit provider write.
  resource_provider_registrations = "none"
  storage_use_azuread             = true
  features {
    key_vault {
      # Preserve the retired vault during its soft-delete retention period.
      purge_soft_delete_on_destroy = false
    }
    postgresql_flexible_server {
      restart_server_on_configuration_value_change = false
    }
  }
}
