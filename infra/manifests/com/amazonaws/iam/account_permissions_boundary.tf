/* IAM Permissions Boundary - Restrict Services */

// Data ========================================================================
data "aws_iam_policy_document" "global_permissions_boundary" { // trivy:ignore:AWS-0345
  statement {                                                  // Restrict boundary to pre-approved resources
    sid       = "RestrictAllowedResources"
    effect    = "Allow"
    actions   = [for resource in local.allowed_services : "${resource}:*"]
    resources = ["*"]
  }

  statement { // Prevent role from removing its own boundary
    sid       = "DenyBoundaryBypass"
    effect    = "Deny"
    resources = ["*"]
    actions = [
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteUserPermissionsBoundary",
      "iam:PutRolePermissionsBoundary",
      "iam:PutUserPermissionsBoundary",
    ]
  }

  statement { // Require all new IAM roles to also enforce the boundary
    sid       = "EnforceBoundaryOnNewRoles"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${local.aws_account_id}:policy/${local.namespace}-iam-policy-permissionsboundary"]
    }
  }
}

// Resources ===================================================================
resource "aws_iam_policy" "global_permissions_boundary" {
  name   = "${local.namespace}-iam-policy-permissionsboundary"
  policy = data.aws_iam_policy_document.global_permissions_boundary.json
  path   = "/global/policies/"
  tags   = { Name = "${local.namespace}-iam-policy-permissionsboundary" }
}

// Outputs =====================================================================
output "admin_permissions_boundary_policy_name" {
  description = "Name of the global account permissions boundary policy"
  value       = aws_iam_policy.global_permissions_boundary.name
  sensitive   = false
}
