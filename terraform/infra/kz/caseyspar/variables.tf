################################################################################
# Variables
#

# AWS ==========================================================================
variable "aws_region" {
  description = "AWS region to deploy to."
  type        = string
  sensitive   = false
  default     = "us-west-2"
}

# Cloudflare ===================================================================
variable "mx_servers" {
  description = "MX servers for root domain. Syntax: {server: priority}."
  type        = map(string)
  sensitive   = false
  default = {
    "mail.protonmail.ch"    = 10
    "mailsec.protonmail.ch" = 20
  }
}

variable "spf_senders" {
  description = "List of allowed SPF senders, like: [\"include:_spf.example.com\", \"ip4:127.0.0.1\"]."
  type        = list(string)
  sensitive   = false
  default = [
    "include:_spf.protonmail.ch",
    "mx"
  ]
}

variable "txt_records" {
  description = "List of TXT records for domain."
  type        = map(string)
  sensitive   = false
  default = {
    "did=did:plc:eop37ikcn6s33dedyhvejqv5"                                  = "_atproto"
    "keybase-site-verification=tlIvxzz3OeL0u3nDrGVYrXRlNX0o62Xm0daTHOfLTQI" = "@"
  }
}

# Misc. ========================================================================
variable "root_domain" {
  description = "Root domain of Terraform infrastructure."
  type        = string
  sensitive   = false
  default     = "caseyspar.kz"
}
