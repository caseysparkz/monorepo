/* IAM */

locals {}

// Data ========================================================================
data "aws_iam_policy_document" "allow_bedrock_usage" {
  statement { // AllowInvokeModelViaInferenceProfile
    sid    = "AllowInvokeModelViaInferenceProfile"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = concat(
      var.enabled ? [aws_bedrock_inference_profile.this[0].arn] : [],
      [data.aws_bedrock_inference_profile.this.inference_profile_arn],
      // Cross-region calls are also authorized against the foundation model in each destination region.
      data.aws_bedrock_inference_profile.this.models[*].model_arn,
    )

    condition { // Mitigate confused deputy
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
  }

  statement { // AllowDiscoverInferenceProfiles
    sid    = "AllowDiscoverInferenceProfiles"
    effect = "Allow"
    actions = [
      "bedrock:GetFoundationModels",
      "bedrock:GetProvisionedModelThroughputs",
      "bedrock:ListFoundationModels",
      "bedrock:ListInferenceProfiles",
      "bedrock:ListProvisionedModelThroughputs",
    ]
    resources = ["*"]
  }
}

// Resources ===================================================================
resource "aws_iam_policy" "allow_bedrock_usage" {
  description = "Allow AWS Bedrock usage."
  path        = "/"
  policy      = data.aws_iam_policy_document.allow_bedrock_usage.json
  tags        = { Name = "${local.namespace}-iam-policy-allowbedrockusage" }
}

// Outputs =====================================================================
