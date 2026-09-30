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

// Resources ===================================================================
resource "aws_bedrock_use_case_for_model_access" "this" {
  form_data = jsonencode(var.aws_bedrock_use_case_for_model_access)

  lifecycle { ignore_changes = [form_data] }
}

// Modules =====================================================================
module "aws_resourcegroups_group" {
  depends_on          = [aws_bedrock_use_case_for_model_access.this]
  source              = "../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

module "bedrock" {
  source                                = "../../../../modules/bedrock"
  enabled                               = var.enabled
  aws_bedrock_foundation_model_id       = var.aws_bedrock_foundation_model_id
  aws_bedrock_cross_region              = var.aws_bedrock_cross_region
  resource_name_prefix                  = local.namespace
  aws_bedrock_use_case_for_model_access = var.aws_bedrock_use_case_for_model_access
}

// Outputs =====================================================================
output "aws_region" {
  description = "Region of the provisioned resourses."
  sensitive   = false
  value       = var.aws_region
}
