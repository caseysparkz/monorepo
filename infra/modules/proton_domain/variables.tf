################################################################################
# Variables
#
# Author:       Casey Sparks
# Date:         August 04, 2025
# Description:  Varibales needed to set up and verify a new ProtonMail domain.

variable "cloudflare_zone_id" {
  type        = string
  description = "Zone ID of the Cloudflare zone to edit."
  sensitive   = true
}

variable "cloudflare_comment" {
  type        = string
  description = "Default comment to be applied to all Cloudflare records."
  sensitive   = false
  default     = ""
}

variable "domain" {
  type        = string
  description = "Domain to verify."
  sensitive   = false
}

variable "txt_verification" {
  type        = string
  description = "Verification DNS TXT record."
  sensitive   = false
}

variable "mx_record" {
  type        = map(string)
  description = "DNS MX records."
  sensitive   = false
  default = {
    "mail.protonmail.ch"    = 10
    "mailsec.protonmail.ch" = 20
  }
}

variable "spf_record" {
  type        = string
  description = "DNS SPF (TXT) record."
  sensitive   = false
  default     = "v=spf1 include:_spf.protonmail.ch ~all"
}

variable "dkim_record" {
  type        = map(string)
  description = "Map of DNS DKIM (CNAME) records."
  sensitive   = false
}

variable "dmarc_policy" {
  type        = string
  description = "DMARC policy for TXT record, minus version key."
  sensitive   = false
  default     = "p=quarantine"
}
