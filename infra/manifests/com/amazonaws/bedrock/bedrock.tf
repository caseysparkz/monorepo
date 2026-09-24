/* AWS Bedrock */

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
resource "aws_bedrock_use_case_for_model_access" "this" {
  // Required by almost all Anthropic models.
  form_data = jsonencode({
    companyName         = "CaseySparkz"
    companyWebsite      = "https://www.caseysparkz.com"
    intendedUsers       = "1"
    industryOption      = "Software"
    otherIndustryOption = ""
    useCases            = ". - Generating developer documentation\n- Code generation/refactoring\n- Summarization of issues / documents"
  })
}

resource "aws_bedrock_foundation_model_agreement" "this" {
  model_id    = data.aws_bedrock_foundation_model.this.model_id
  offer_token = data.aws_bedrock_foundation_model_agreement_offers.this.offers[0].offer_token

  lifecycle { ignore_changes = [offer_token] }
}

resource "aws_bedrock_inference_profile" "this" {
  count = var.enabled ? 1 : 0
  // Application inference profile for tagging and cost tracking.
  depends_on = [
    aws_bedrock_use_case_for_model_access.this,
    aws_bedrock_foundation_model_agreement.this,
  ]

  name        = "${local.namespace}-inference-profile"
  description = "Application inference profile for ${var.aws_bedrock_foundation_model_id}."
  tags        = { Name = "${local.namespace}-bedrock-inferenceprofile" }

  model_source { copy_from = data.aws_bedrock_inference_profile.this.inference_profile_arn }
}

// Outputs =====================================================================
