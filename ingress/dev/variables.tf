variable "kubeconfig_path" {
  type        = string
  description = "Path to the operator kubeconfig for the target AKS cluster."
}

variable "kubeconfig_context" {
  type        = string
  description = "Kubernetes context name for the target cluster."
}

variable "dns_subscription_id" {
  type        = string
  description = "Subscription ID containing the existing Azure DNS zone."
}

variable "dns_resource_group" {
  type        = string
  description = "Resource group containing the existing Azure DNS zone."
}

variable "dns_zone_name" {
  type        = string
  description = "Existing DNS zone name."
}

variable "dns_record_name" {
  type        = string
  description = "A record label in the DNS zone."
}

variable "dns_ttl" {
  type        = number
  description = "TTL in seconds for the existing A record."
}

variable "hostname" {
  type        = string
  description = "Private HTTPS hostname served by the gateway."
}

variable "private_ip" {
  type        = string
  description = "Reserved private frontend IP for the internal load balancer."
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace containing the API and gateway."
  default     = "braintrust"
}

variable "gateway_name" {
  type        = string
  description = "Gateway API resource name."
  default     = "braintrust-private"
}

variable "route_name" {
  type        = string
  description = "HTTPRoute resource name."
  default     = "braintrust-api-private"
}

variable "api_service_name" {
  type        = string
  description = "Kubernetes Service name for the Braintrust API."
  default     = "braintrust-api"
}

variable "tls_certificate_uri" {
  type        = string
  description = "Key Vault certificate URI configured for the HTTPS listener."
}

variable "tls_service_account" {
  type        = string
  description = "Kubernetes service account authorized to retrieve the certificate."
}
