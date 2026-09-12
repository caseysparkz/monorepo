/* AWS Bedrock */

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/bedrock_foundation_model

locals {
  aws_bedrock_foundation_model_id = [
    for model in data.aws_bedrock_foundation_models.this.model_summaries :
    model.model_id if model.model_name == var.aws_bedrock_foundation_model_name
  ][0]
}

// Data ========================================================================
data "aws_bedrock_foundation_models" "this" {}

data "aws_bedrock_inference_profiles" "this" {}

data "aws_bedrock_foundation_model" "this" {
  // Find Bedrock Foundation model ID for name + region.
  model_id = local.aws_bedrock_foundation_model_id
}

data "aws_bedrock_foundation_model_agreement_offers" "this" {
  model_id   = local.aws_bedrock_foundation_model_id
  offer_type = "PUBLIC"
}

// Resources ===================================================================
resource "aws_bedrock_foundation_model_agreement" "this" {
  // Manage the AWS Bedrock Foundation Model agreement.
  model_id = local.aws_bedrock_foundation_model_id
  offer_token = data.aws_bedrock_foundation_model_agreement_offers.this.offers[0].offer_token

  lifecycle { ignore_changes = [offer_token] }
}

/*
resource "aws_bedrock_guardrail" "this" { // TODO
  // Implement guardrails around models prompts and outputs.
  // <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrock_guardrail>
  name = "" // TODO
  blocked_input_messaging = "" // TODO
  blocked_outputs_messaging = "" // TODO
  description = "" // TODO

  content_policy_config {
    tier_config { tier_name = "STANDARD" }

    filters_config {
      input_strength = "MEDIUM"
      output_strength = "MEDIUM"
      type = "HATE"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      action = "BLOCK"
      input_action = "BLOCK"
      output_action = "ANONYMIZE"
      input_enabled = true
      output_enabled = true
      type = "NAME"
    }
  }

  topic_policy_config {
    tier_config { tier_name = "CLASSIC" }

    topics_config {
      name = "investment_topic"
      examples = [ // TODO
        "Generate a quantatative analysis of a company.",
        "Generate a quantatative model for a vertical.",
        "Generate an investment stratagy for an industry.",
      ]
      type = "ALLOW"
      definition = <<-EOT
        Investment advice refers to inquiries, guidance, or recommendations regarding the management or allocation of
        funds or assets with the goal of generating returns.
      EOT
    }
  }

  word_policy_config {
    managed_word_lists_config { type = "PROFANITY" } // TODO
    words_config { text = "HATE" } // TODO
  }
}

// Outputs =====================================================================
*/
