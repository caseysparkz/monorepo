/* Main */

locals {
  aws_account_id = data.aws_caller_identity.this.account_id
  environment    = "prod"
  project        = "iam"
  application    = "githubactions"
  namespace      = "${local.environment}-${local.project}-${local.application}"
  tfstate_bucket = "com.caseysparkz.tfstate"
  common_tags = {
    Application = local.application
    Domain      = "github.com"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
    Repo        = "github.com/caseysparkz/monorepo"
    RepoPath    = "infra/manifests/com/amazonaws/iam/github_actions"
  }
}

// Data ========================================================================
data "aws_caller_identity" "this" {}

data "terraform_remote_state" "tfstate" {
  backend = "s3"
  config = {
    bucket       = "com.caseysparkz.tfstate"
    key          = "tfstate.tfstate"
    region       = "us-west-2"
    use_lockfile = true
  }
}

// Resources ===================================================================
resource "aws_iam_openid_connect_provider" "this" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = { Name = "${local.namespace}-iam-oidc-provider-gha" }
}

// Modules =====================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = { Namespace = local.namespace }
}
