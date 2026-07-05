################################################################################
# Main
#

locals {
  aws_region     = data.aws_region.this.region
  aws_account_id = data.aws_caller_identity.this.account_id
  environment    = "prod"
  project        = "caseysparkz"
  application    = "ecr"
  namespace      = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Domain      = "ecr.${var.root_domain}"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
  }
}

# Data =========================================================================
data "aws_caller_identity" "this" {}

data "aws_region" "this" {}

# Resources ====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

# Modules ======================================================================
module "ecr" {
  source             = "../../../../modules/ecr"
  root_domain        = var.root_domain
  docker_compose_dir = abspath("../../../../docker/")
  aws_kms_key_arn    = "arn:aws:kms:${local.aws_region}:${local.aws_account_id}:key/de8cf575-e753-44b5-9331-fa1762775478"
  docker_socket      = var.docker_socket
}

# Outputs ======================================================================
output "ecr_registry_url" {
  description = "URL of the deployed ECR registry."
  value       = module.ecr.ecr_registry_url
  sensitive   = false
}

output "ecr_registry_repository_urls" {
  description = "List of URLs for the deployed ECR registry repositories."
  value       = module.ecr.ecr_registry_repository_urls
  sensitive   = false
}
