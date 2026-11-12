import {
  to = kubernetes_manifest.gateway
  id = "apiVersion=gateway.networking.k8s.io/v1,kind=Gateway,namespace=${var.namespace},name=${var.gateway_name}"
}

import {
  to = kubernetes_manifest.route
  id = "apiVersion=gateway.networking.k8s.io/v1,kind=HTTPRoute,namespace=${var.namespace},name=${var.route_name}"
}

import {
  to = azurerm_dns_a_record.braintrust
  id = "/subscriptions/${var.dns_subscription_id}/resourceGroups/${var.dns_resource_group}/providers/Microsoft.Network/dnsZones/${var.dns_zone_name}/A/${var.dns_record_name}"
}
