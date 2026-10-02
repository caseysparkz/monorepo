/* IAM: Admin */

// Data ========================================================================
data "aws_iam_policy_document" "admin" {
  // Allow GitHub Actions to perform write actions.
  statement {
    sid     = "GitHubActionsAssumeWriteRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:caseysparkz@45407933/monorepo@578333854:ref:refs/heads/main"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

// Resources ===================================================================
resource "aws_iam_role" "admin" {
  depends_on           = [aws_iam_openid_connect_provider.this]
  name                 = "${local.namespace}-iam-role-ghaadmin"
  description          = "IAM role assumed by GitHub Actions allowing Terraform deployments."
  assume_role_policy   = data.aws_iam_policy_document.admin.json
  max_session_duration = 3600 // Min. allowable
  tags                 = { Name = "${local.namespace}-iam-role-ghaadmin" }
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

// Outputs =====================================================================
output "aws_role_arn_admin" {
  description = "ARN of the admin AWS IAM role for GitHub Actions (AWS admin for main branch only)."
  value       = aws_iam_role.admin.arn
  sensitive   = true
}
