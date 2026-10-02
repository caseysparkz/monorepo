/* IAM: ReadOnly */

locals {
  ci_secrets = [ // Needed by the ReadOnly account to perform `terraform plan`
    "ansible/vault",
    "cloudflare/api_token",
    "dagger/api_token",
  ]
}

// Data ========================================================================
data "aws_iam_policy_document" "assumerole_readonly" {
  // Allow GitHub Actions to perform read actions.
  statement {
    sid     = "GitHubActionsAssumeReadOnlyRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:caseysparkz@45407933/monorepo@578333854:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "readonly" {
  // Allow GitHub Actions to read Terraform state and CI secrets
  statement { // AllowTfstateLocking
    sid    = "AllowTfstateLocking"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${local.tfstate_bucket}/*.tflock"]
  }

  statement { // AllowKmsDecryptTfstate
    sid       = "AllowKmsDecryptTfstate"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.terraform_remote_state.tfstate.outputs.aws_kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region}.amazonaws.com"]
    }
  }

  statement { // AllowReadCiSecrets
    sid     = "AllowReadCiSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      for secret in local.ci_secrets :
      "arn:aws:secretsmanager:${var.aws_region}:${local.aws_account_id}:secret:${secret}-*"
    ]
  }
}

// Resources ===================================================================
resource "aws_iam_role" "readonly" {
  depends_on           = [aws_iam_openid_connect_provider.this]
  name                 = "${local.namespace}-iam-role-ghareadonly"
  description          = "Read-only IAM role assumed by GitHub Actions for CI checks and Terraform plans."
  assume_role_policy   = data.aws_iam_policy_document.assumerole_readonly.json
  max_session_duration = 3600
  tags                 = { Name = "${local.namespace}-iam-role-ghareadonly" }
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "readonly" {
  name   = "${local.namespace}-iam-role-policy-readonlytfstate"
  role   = aws_iam_role.readonly.id
  policy = data.aws_iam_policy_document.readonly.json
}

// Outputs =====================================================================
output "aws_role_arn_readonly" {
  description = "ARN of the read-only AWS IAM role for GitHub Actions (AWS readonly for CI checks and terraform plans)."
  value       = aws_iam_role.readonly.arn
  sensitive   = true
}
