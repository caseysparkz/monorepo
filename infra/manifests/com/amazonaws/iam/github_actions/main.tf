################################################################################
# Main
#

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  environment    = "prod"
  project        = "iam"
  application    = "githubactions"
  namespace      = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    Application = local.application
    Domain      = "github.com"
    Environment = local.environment
    ManagedBy   = "terraform"
    Namespace   = local.namespace
    Project     = local.project
  }
}

# Data =========================================================================
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "this" {
  statement {
    sid     = "GitHubActionsAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringLike"
      values   = ["repo:caseysparkz/infrastructure:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }

    condition {
      test     = "StringLike"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
  }
}

# Modules ======================================================================
module "aws_resourcegroups_group" {
  source              = "../../../../../modules/aws_resourcegroup_by_tagset"
  resource_group_name = "${local.namespace}-rg"
  common_tags         = local.common_tags
}

# Resources ====================================================================
resource "aws_iam_openid_connect_provider" "this" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = { Name = "${local.namespace}-iam-idp" }
}

resource "aws_iam_role" "this" {
  depends_on           = [aws_iam_openid_connect_provider.this]
  name                 = "${local.namespace}-iam-role"
  description          = "IAM role assumed by GitHub Actions allowing Terraform deployments."
  assume_role_policy   = data.aws_iam_policy_document.this.json
  max_session_duration = 3600 # Min. allowable
  tags                 = { Name = "${local.namespace}-iam-role" }
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  /*
   Unfortunately over-scoped, but GHA/Terraform action may need to perform
   any arbitrary action.
  */
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Outputs ======================================================================
output "aws_role_arn" {
  description = "ARN of the AWS IAM role for GitHub Actions to assume."
  value       = aws_iam_role.this.arn
  sensitive   = true
}
