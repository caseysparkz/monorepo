/*
Main

Author:       Casey Sparks
Date:         September 12, 2026
Description:  x
*/

locals {
  environment = "prod"
  project     = "bedrock"
  application = "ai"
  namespace   = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Environment = local.environment
    ManagedBy   = "terraform"
    Project     = local.project
    Repo        = "github.com/caseysparkz/monorepo"
    RepoPath    = "infra/manifests/com/amazonaws/bedrock"
  }
}

// Data ========================================================================

// Modules =====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

// Resources ===================================================================

// Outputs =====================================================================
