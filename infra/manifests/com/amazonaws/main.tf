/*
Main

Author:       Casey Sparks
Date:         July 28, 2026
Description:  Minimal security configurations and organization policies.
*/

locals {
  aws_account_id = data.aws_caller_identity.this.account_id
  environment    = "all"
  project        = "aws"
  application    = "config"
  namespace      = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
    Repo        = "github.com/caseysparkz/monorepo"
    RepoPath    = "infra/manifests/com/amazonaws"
  }
}

// Data ========================================================================
data "aws_caller_identity" "this" {}

// Modules =====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

// Resources ===================================================================
resource "aws_organizations_organization" "this" {
  feature_set              = "ALL"
  return_organization_only = false
  aws_service_access_principals = [
    "cost-optimization-hub.bcm.amazonaws.com",
    "notifications.amazonaws.com",
    "sso.amazonaws.com",
  ]
  enabled_policy_types = [
    "AISERVICES_OPT_OUT_POLICY",
    "DECLARATIVE_POLICY_EC2",
    "SERVICE_CONTROL_POLICY",
    //"BACKUP_POLICY",
    //"BEDROCK_POLICY",
    //"CHATBOT_POLICY",
    //"INSPECTOR_POLICY",
    //"RESOURCE_CONTROL_POLICY",
    //"S3_POLICY",
    //"SECURITYHUB_POLICY",
    //"TAG_POLICY",
    //"UPGRADE_ROLLOUT_POLICY",
  ]
}

resource "aws_ebs_encryption_by_default" "this" { enabled = true } // Require EBS encryption

resource "aws_ec2_instance_metadata_defaults" "this" {
  http_tokens                 = "required" // Require IMDSv2
  http_endpoint               = "enabled"
  http_put_response_hop_limit = 16
  instance_metadata_tags      = "enabled"
}
