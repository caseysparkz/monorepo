################################################################################
# Main
#

locals {
  environment = "prod"
  project     = "caseysparkz"
  application = "photos"
  namespace   = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Domain      = "photos.caseysparkz.com"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
  }
}

# Data =========================================================================
data "aws_caller_identity" "this" {}

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
