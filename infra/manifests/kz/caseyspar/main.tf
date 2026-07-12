################################################################################
# Main
#

locals {
  dmarc_list = [ # Parsed to string
    { key = "p", value = "reject" },
    { key = "sp", value = "reject" },
    { key = "adkim", value = "s" },
    { key = "aspf", value = "s" },
    { key = "fo", value = 1 },
    { key = "pct", value = 5 },
    { key = "rua", value = "mailto:dmarc_rua@${var.root_domain}" },
    { key = "ruf", value = "mailto:dmarc_ruf@${var.root_domain}" },
  ]
  dmarc_policy       = join(";", [for item in local.dmarc_list : "${item.key}=${item.value}"]) # Parse local.dmarc_list
  cloudflare_comment = "Terraform managed."
  cloudflare_zone_id = data.cloudflare_zones.root_domain.result[0].id
  cloudflare_zone_settings = {
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    http3                    = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    ssl                      = "flexible"
    tls_1_3                  = "on"
  }
}

# Data =========================================================================
data "cloudflare_zones" "root_domain" { name = var.root_domain }

# Resources ====================================================================
# Cloudflare -------------------------------------------------------------------
resource "cloudflare_zone_setting" "root_zone" {
  for_each   = local.cloudflare_zone_settings
  zone_id    = local.cloudflare_zone_id
  setting_id = each.key
  value      = each.value
}

# Modules ======================================================================
# Proton: @ --------------------------------------------------------------------
module "proton" {
  source             = "../../../modules/proton_domain"
  cloudflare_zone_id = local.cloudflare_zone_id
  cloudflare_comment = local.cloudflare_comment
  domain             = var.root_domain
  txt_verification   = "protonmail-verification=bc5816f2765b404f9a7ca06d635c2ead61fdfe82"
  dmarc_policy       = local.dmarc_policy
  dkim_record = {
    "protonmail._domainkey"  = "protonmail.domainkey.dvjouhoyu2azb2o522cqwbynlvqcp3b4lwqrmv5curwfg7bcit5ka.domains.proton.ch"
    "protonmail2._domainkey" = "protonmail2.domainkey.dvjouhoyu2azb2o522cqwbynlvqcp3b4lwqrmv5curwfg7bcit5ka.domains.proton.ch"
    "protonmail3._domainkey" = "protonmail3.domainkey.dvjouhoyu2azb2o522cqwbynlvqcp3b4lwqrmv5curwfg7bcit5ka.domains.proton.ch"
  }
}
