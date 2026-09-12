/* IAM */

locals {}

// Data ========================================================================
data "aws_iam_policy_document" "bedrock_user" {
  statement {
    sid    = "ProvisionedThroughputModelInvocation"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      "arn:aws:bedrock:us-east-1:123456789012:provisioned-model/my-provisioned-model",
    ]
  }
}


// Modules =====================================================================

// Resources ===================================================================

// Outputs =====================================================================
