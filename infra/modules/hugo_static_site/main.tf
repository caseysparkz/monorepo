###############################################################################
# Main
#

locals {
  common_tags = merge(var.common_tags, { Service = var.subdomain })
  email_headers = {
    default_recipient = "contact@${var.root_domain}"
    default_sender    = "contact@${var.subdomain}"
  }
  reverse_dns_subdomain_dir = join(".", reverse(split(".", var.subdomain)))
}

# Data =========================================================================
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
