/*
Main

Author:       Casey Sparks
Date:         September 29, 2026
Description:  IAM Identity Center manifests
*/

locals {
  aws_ssoadmin_region       = "us-east-1"
  aws_ssoadmin_instance_arn = data.aws_ssoadmin_instances.this.arns[0]
  environment               = "prod"
  project                   = "aws"
  application               = "identitycenter"
  namespace                 = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Environment = local.environment
    Namespace   = local.namespace
    ManagedBy   = "terraform"
    Project     = local.project
    Repo        = "github.com/PrimordiumLabs/infrasec"
    RepoPath    = "terraform/com/amazonaws/iam/ssoadmin_permissionsets"
  }
}

// Data ========================================================================
data "aws_ssoadmin_instances" "this" { region = local.aws_ssoadmin_region }

// Resources ===================================================================

// Modules =====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = { Namespace = local.namespace }
}
