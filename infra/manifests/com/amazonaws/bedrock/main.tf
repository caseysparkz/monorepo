/*
Main

Author:       Casey Sparks
Date:         September 12, 2026
Description:  Testing out a Bedrock environment.
*/

locals {
  aws_account_id = data.aws_caller_identity.this.account_id
  environment    = "prod"
  project        = "ai"
  application    = replace(split(".", var.aws_bedrock_foundation_model_id)[1], "-", "") // Evaluates to model name
  namespace      = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Environment = local.environment
    ManagedBy   = "terraform"
    Project     = local.project
    Repo        = "github.com/caseysparkz/monorepo"
    RepoPath    = "infra/manifests/com/amazonaws/bedrock"
    ModelId     = var.aws_bedrock_foundation_model_id
  }
}

// Data ========================================================================
data "aws_caller_identity" "this" {}

data "terraform_remote_state" "this" {
  backend = "s3"
  config = {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/caseysparkz.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

// Modules =====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

// Resources ===================================================================

// Outputs =====================================================================
output "aws_region" {
  description = "Region of the provisioned resourses."
  sensitive   = false
  value       = var.aws_region
}
