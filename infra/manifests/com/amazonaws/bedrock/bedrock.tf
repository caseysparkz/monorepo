/* AWS Bedrock */

// Data ========================================================================
data "aws_bedrock_foundation_model" "this" { model_id = var.aws_bedrock_foundation_model_id }

data "aws_bedrock_foundation_model_agreement_offers" "this" {
  model_id   = data.aws_bedrock_foundation_model.this.model_id
  offer_type = "PUBLIC"
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

/* TODO:
resource "aws_bedrock_provisioned_model_throughput" "this" {
  depends_on             = [aws_bedrock_use_case_for_model_access.this]
  model_arn              = data.aws_bedrock_foundation_model.this.model_arn
  provisioned_model_name = "${local.namespace}-${replace(data.aws_bedrock_foundation_model.this.id, ".", "-")}-T${var.aws_bedrock_model_throughput}"
  model_units            = var.aws_bedrock_model_throughput
  //commitment_duration = "SixMonths" # or "OneMonth"
  tags = { Name = "${local.namespace}-bedrock-provisionedmodelthroughput" }
}

resource "aws_bedrock_custom_model" "this" {}
resource "aws_bedrock_evaluation_job" "this" {}
resource "aws_bedrock_guardrail" "this" {}
resource "aws_bedrock_guardrail_version" "this" {}
resource "aws_bedrock_inference_profile" "this" {}
resource "aws_bedrock_model_invocation_job" "this" {}
resource "aws_bedrock_model_invocation_logging_configuration" "this" {}
*/

// Outputs =====================================================================
