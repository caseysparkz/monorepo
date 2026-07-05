################################################################################
# Main
#

locals {
  environment = "prod"
  project     = "caseysparkz"
  application = "root"
  namespace   = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Domain      = var.root_domain
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
  }
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
# AWS::KMS ---------------------------------------------------------------------
resource "aws_kms_key" "this" {
  description             = "KMS key to encrypt domain artifacts/S3 bucket objects."
  deletion_window_in_days = 30
  tags                    = { Name = "${local.namespace}-kms-key" }
}

# Cloudflare -------------------------------------------------------------------
resource "cloudflare_zone_setting" "root_zone" {
  for_each   = local.cloudflare_zone_settings
  zone_id    = local.cloudflare_zone_id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_dns_record" "txt" {
  for_each = var.txt_records
  zone_id  = local.cloudflare_zone_id
  name     = each.value
  content  = each.key
  type     = "TXT"
  ttl      = 1
  proxied  = false
  comment  = local.cloudflare_comment
}

resource "cloudflare_dns_record" "pka" {
  for_each = var.pka_records
  zone_id  = local.cloudflare_zone_id
  name     = "${each.key}._pka"
  content  = "v=pka1; fpr=${each.value}"
  type     = "TXT"
  ttl      = 1
  proxied  = false
  comment  = local.cloudflare_comment
}

# Modules ======================================================================
# AWS::ResourceGroups ----------------------------------------------------------
module "aws_resourcegroups_group" {
  source              = "../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

# Proton: @ --------------------------------------------------------------------
module "proton" {
  source             = "../../../modules/proton_domain"
  cloudflare_zone_id = local.cloudflare_zone_id
  cloudflare_comment = local.cloudflare_comment
  domain             = var.root_domain
  txt_verification   = "protonmail-verification=af8861ffc1961e58bfc47af155f91c468923c49d"
  dmarc_policy       = local.dmarc_policy
  dkim_record = {
    "protonmail._domainkey"  = "protonmail.domainkey.d56wvdqzbgjl657p6p37duzymskqqisyreca5lrft72j35tshomoq.domains.proton.ch"
    "protonmail2._domainkey" = "protonmail2.domainkey.d56wvdqzbgjl657p6p37duzymskqqisyreca5lrft72j35tshomoq.domains.proton.ch"
    "protonmail3._domainkey" = "protonmail3.domainkey.d56wvdqzbgjl657p6p37duzymskqqisyreca5lrft72j35tshomoq.domains.proton.ch"
  }
}

# Proton: home. ----------------------------------------------------------------
module "proton_home" {
  source             = "../../../modules/proton_domain"
  cloudflare_zone_id = local.cloudflare_zone_id
  cloudflare_comment = local.cloudflare_comment
  domain             = "home.${var.root_domain}"
  txt_verification   = "protonmail-verification=9b021e210af76144b6841abcc22762b764d6636b"
  mx_record          = {}
  spf_record         = "v=spf1 include:_spf.protonmail.ch -all"
  dmarc_policy       = local.dmarc_policy
  dkim_record = {
    "protonmail._domainkey"  = "protonmail.domainkey.d4gc64isfcsi5uij7rmm2nggww7zvww7zvmtyw5guqxefeghia2wq.domains.proton.ch"
    "protonmail2._domainkey" = "protonmail2.domainkey.d4gc64isfcsi5uij7rmm2nggww7zvww7zvmtyw5guqxefeghia2wq.domains.proton.ch"
    "protonmail3._domainkey" = "protonmail3.domainkey.d4gc64isfcsi5uij7rmm2nggww7zvww7zvmtyw5guqxefeghia2wq.domains.proton.ch"
  }
}

# Outputs ======================================================================
output "aws_kms_key_id" {
  description = "ID of the KMS key used to encrypt all domain artifacts."
  value       = aws_kms_key.this.key_id
  sensitive   = false
}

output "aws_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt all domain artifacts."
  value       = aws_kms_key.this.arn
  sensitive   = false
}
