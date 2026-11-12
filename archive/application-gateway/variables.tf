variable "frontend_private_ip" {
  type        = string
  description = "Static IP reserved by Network in the dedicated 000 gateway subnet."

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}[.]){3}[0-9]{1,3}$", var.frontend_private_ip))
    error_message = "Provide the approved private frontend IP address."
  }
}

variable "certificate_secret_id" {
  type        = string
  description = "Versionless HTTPS Key Vault secret URI for the approved TLS certificate."

  validation {
    condition     = can(regex("^https://[a-z0-9-]+\\.vault\\.azure\\.net/secrets/[A-Za-z0-9-]+/?$", var.certificate_secret_id))
    error_message = "Provide the versionless Key Vault secret URI, without the secret value."
  }
}

variable "certificate_identity_id" {
  type        = string
  description = "Resource ID of the approved gateway identity with access to the certificate secret."
}

variable "waf_policy_id" {
  type        = string
  description = "Resource ID of the approved WAF policy for Braintrust DEV."
}

variable "tags" {
  type        = map(string)
  description = "Approved corporate tags for the Braintrust DEV gateway."
}
