terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.27.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  subscription_id                 = "000"
  resource_provider_registrations = "none"

  features {}
}

data "azurerm_subnet" "gateway" {
  name                 = "000"
  virtual_network_name = "000"
  resource_group_name  = "000"
}

resource "azurerm_application_gateway" "braintrust" {
  name                = "000"
  resource_group_name = "000"
  location            = "eastus2"
  firewall_policy_id  = var.waf_policy_id
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.certificate_identity_id]
  }

  gateway_ip_configuration {
    name      = "gateway"
    subnet_id = data.azurerm_subnet.gateway.id
  }

  frontend_ip_configuration {
    name                          = "private"
    subnet_id                     = data.azurerm_subnet.gateway.id
    private_ip_address            = var.frontend_private_ip
    private_ip_address_allocation = "Static"
  }

  frontend_port {
    name = "https"
    port = 443
  }

  ssl_certificate {
    name                = "braintrust-dev-tls"
    key_vault_secret_id = var.certificate_secret_id
  }

  http_listener {
    name                           = "bootstrap-https"
    frontend_ip_configuration_name = "private"
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_name                      = "000"
    ssl_certificate_name           = "braintrust-dev-tls"
    require_sni                    = true
  }

  backend_address_pool {
    name = "bootstrap-empty"
  }

  backend_http_settings {
    name                  = "bootstrap-http"
    cookie_based_affinity = "Disabled"
    port                  = 8000
    protocol              = "Http"
    request_timeout       = 30
  }

  request_routing_rule {
    name                       = "bootstrap"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "bootstrap-https"
    backend_address_pool_name  = "bootstrap-empty"
    backend_http_settings_name = "bootstrap-http"
  }

  lifecycle {
    # AGIC owns routing after it is attached to this dedicated gateway.
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule,
      rewrite_rule_set,
      url_path_map,
    ]
  }
}

output "application_gateway_id" {
  value = azurerm_application_gateway.braintrust.id
}

output "frontend_private_ip" {
  value = var.frontend_private_ip
}
