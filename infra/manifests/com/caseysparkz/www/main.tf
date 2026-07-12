################################################################################
# Main
#

locals {
  environment     = "prod"
  project         = "caseysparkz"
  application     = "www"
  namespace       = "${local.environment}-${local.project}-${local.application}"
  aws_kms_key_arn = data.terraform_remote_state.this.outputs.aws_kms_key_arn
  common_tags = {
    Application = local.application
    Domain      = "www.${data.terraform_remote_state.this.outputs.root_domain}"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
  }
}

# Data =========================================================================
data "terraform_remote_state" "this" {
  backend = "s3"
  config = {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/caseysparkz.tfstate"
    region       = "us-west-2"
    use_lockfile = true
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
  root_domain = data.terraform_remote_state.this.outputs.root_domain
  kms_key_arn = data.terraform_remote_state.this.outputs.aws_kms_key_arn
}

module "www" {
  source                        = "../../../../modules/hugo_static_site"
  root_domain                   = data.terraform_remote_state.this.outputs.root_domain
  subdomain                     = "www.${data.terraform_remote_state.this.outputs.root_domain}"
  artifact_bucket_id            = module.artifacts.s3_bucket_id
  site_title                    = data.terraform_remote_state.this.outputs.root_domain
  hugo_dir                      = abspath("files")
  js_contact_form_template_path = abspath("files/static/js/contactForm.js.tftpl")
  common_tags                   = local.common_tags
  aws_kms_key_arn               = data.terraform_remote_state.this.outputs.aws_kms_key_arn
}
