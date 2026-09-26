/* Main */

locals {
  aws_account_id = data.aws_caller_identity.this.account_id
  environment    = "prod"
  project        = "caseysparkz"
  application    = "store"
  namespace      = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Domain      = "${random_uuid.this.id}.caseysparkz.com"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
    Repo        = "github.com/caseysparkz/monorepo"
    RepoPath    = "infra/manifests/com/caseysparkz/store"
  }
}

// Data ========================================================================
data "aws_caller_identity" "this" {}

// Resources ===================================================================
resource "random_uuid" "this" {}

module "aws_resourcegroups_group" {
  source              = "../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = { Namespace = local.namespace }
}
