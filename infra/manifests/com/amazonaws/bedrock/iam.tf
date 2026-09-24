/* IAM */

locals {}

// Data ========================================================================
data "aws_ssoadmin_instances" "this" {}

data "aws_iam_policy_document" "bedrock_user_policy" {
  /* IAM policy assumed by Bedrock IAM user. */
  statement { // AllowInvokeModelViaInferenceProfile
    sid    = "AllowInvokeModelViaInferenceProfile"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = concat(
      [
        data.aws_bedrock_inference_profile.this.inference_profile_arn,
      ],
      // Cross-region calls are also authorized against the foundation model in each destination region.
      data.aws_bedrock_inference_profile.this.models[*].model_arn,
      var.enabled ? [aws_bedrock_inference_profile.this[0].arn] : [],
    )
  }
}

data "aws_iam_policy_document" "bedrock_user_permissions_boundary" {
  /* IAM permissions boundary imposed on Bedrock IAM user. */
  statement {
    effect    = "Allow"
    actions   = ["bedrock:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_bedrock_usage" {
  statement { // AllowBedrockUsage
    sid    = "AllowBedrockUsage"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [for item in data.aws_bedrock_inference_profile.this.models : item.model_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
  }
}

// Resources ===================================================================
resource "aws_iam_policy" "bedrock_permissions_boundary" {
  description = "Permissions boundary limiting access to Bedrock services only."
  path        = "/permissions-boundaries/"
  policy      = data.aws_iam_policy_document.bedrock_user_permissions_boundary.json
  tags        = { Name = "${local.namespace}-iam-policy-bedrockpermissionsboundary" }
}

resource "aws_iam_policy" "allow_bedrock_usage" {
  description = "Allow AWS Bedrock usage."
  path        = "/"
  policy      = data.aws_iam_policy_document.allow_bedrock_usage.json
  tags        = { Name = "${local.namespace}-iam-policy-allowbedrockusage" }
}

// Outputs =====================================================================
