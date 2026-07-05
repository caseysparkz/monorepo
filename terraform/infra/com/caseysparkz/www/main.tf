################################################################################
# Main
#

locals {
  environment     = "prod"
  project         = "caseysparkz"
  application     = "www"
  namespace       = "${local.environment}-${local.project}-${local.application}"
  aws_kms_key_arn = "arn:aws:kms:${var.aws_region}:${local.aws_account_id}:key/${var.aws_kms_key_id}"
  common_tags = {
    Application = local.application
    Domain      = "www.${var.root_domain}"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
  }
}

# Resources ====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

# Modules ======================================================================
module "artifacts" {
  source      = "../../../../modules/s3_artifacts"
  root_domain = var.root_domain
  kms_key_arn = local.aws_kms_key_arn
}

module "www" {
  source                        = "../../../../modules/hugo_static_site"
  root_domain                   = var.root_domain
  subdomain                     = "www.${var.root_domain}"
  artifact_bucket_id            = module.artifacts.s3_bucket_id
  site_title                    = var.root_domain
  hugo_dir                      = abspath("files")
  js_contact_form_template_path = abspath("files/static/js/contactForm.js.tftpl")
  common_tags                   = local.common_tags
  aws_kms_key_arn               = local.aws_kms_key_arn
}
