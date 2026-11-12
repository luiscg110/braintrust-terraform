terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.27.0, < 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0, < 3.0.0"
    }
  }
}

provider "azurerm" {
  subscription_id                 = var.dns_subscription_id
  resource_provider_registrations = "none"
  features {}
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

locals {
  hostname   = var.hostname
  private_ip = var.private_ip
  namespace  = var.namespace
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = var.gateway_name
      namespace = local.namespace
    }
    spec = {
      gatewayClassName = "approuting-istio"
      infrastructure = {
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
          "service.beta.kubernetes.io/azure-load-balancer-ipv4"     = local.private_ip
        }
      }
      listeners = [{
        name     = "https"
        hostname = local.hostname
        port     = 443
        protocol = "HTTPS"
        tls = {
          mode = "Terminate"
          options = {
            "kubernetes.azure.com/tls-cert-keyvault-uri"    = var.tls_certificate_uri
            "kubernetes.azure.com/tls-cert-service-account" = var.tls_service_account
          }
        }
        allowedRoutes = { namespaces = { from = "Same" } }
      }]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = var.route_name
      namespace = local.namespace
    }
    spec = {
      parentRefs = [{
        name        = kubernetes_manifest.gateway.manifest.metadata.name
        sectionName = "https"
      }]
      hostnames = [local.hostname]
      rules = [{
        matches     = [{ path = { type = "PathPrefix", value = "/" } }]
        backendRefs = [{ name = var.api_service_name, port = 8000 }]
      }]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_dns_a_record" "braintrust" {
  name                = var.dns_record_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_resource_group
  ttl                 = var.dns_ttl
  records             = [local.private_ip]

  lifecycle {
    prevent_destroy = true
  }
}
