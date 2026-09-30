/* Main */

// Data ========================================================================
data "aws_bedrock_foundation_model" "this" { model_id = var.aws_bedrock_foundation_model_id }

data "aws_bedrock_foundation_model_agreement_offers" "this" {
  model_id   = data.aws_bedrock_foundation_model.this.model_id
  offer_type = "PUBLIC"
}

data "aws_bedrock_inference_profile" "this" {
  // US cross-region system inference profile; the only supported invocation path for this model.
  inference_profile_id = "${var.aws_bedrock_cross_region}.${var.aws_bedrock_foundation_model_id}"
}

// Resources ===================================================================
resource "aws_bedrock_foundation_model_agreement" "this" {
  count       = var.enabled ? 1 : 0
  model_id    = data.aws_bedrock_foundation_model.this.model_id
  offer_token = data.aws_bedrock_foundation_model_agreement_offers.this.offers[0].offer_token

  lifecycle { ignore_changes = [offer_token] }
}

resource "aws_bedrock_inference_profile" "this" {
  // Application inference profile for tagging and cost tracking.
  count      = var.enabled ? 1 : 0
  depends_on = [aws_bedrock_foundation_model_agreement.this]

  name        = "${var.resource_name_prefix}-inference-profile"
  description = "Application inference profile for ${var.aws_bedrock_foundation_model_id}."
  tags        = { Name = "${var.resource_name_prefix}-bedrock-inferenceprofile" }

  model_source { copy_from = data.aws_bedrock_inference_profile.this.inference_profile_arn }
}

// Outputs =====================================================================
output "aws_bedrock_inference_profile_arns" {
  description = "ARN of the Bedrock application inference profile. Use as `modelId` when invoking."
  sensitive   = false
  value = concat(
    var.enabled ? [aws_bedrock_inference_profile.this[0].arn] : [],
    [data.aws_bedrock_inference_profile.this.inference_profile_arn],
    data.aws_bedrock_inference_profile.this.models[*].model_arn,
  )
}
