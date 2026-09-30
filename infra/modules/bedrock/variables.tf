/* Variables */
variable "enabled" {
  description = "Whether or not the Bedrock model is enabled."
  type        = bool
  sensitive   = false
  default     = false
}

variable "aws_bedrock_foundation_model_id" {
  description = "ID of the Bedrock foundation model to deploy."
  type        = string
  sensitive   = false
  default     = "anthropic.claude-opus-5"
}

variable "aws_bedrock_cross_region" {
  description = "Cross-region inference profile to use. ['us', 'global']."
  type        = string
  sensitive   = false
  default     = "global" // ~10% cheaper

  validation {
    condition     = contains(["global", "us"], var.aws_bedrock_cross_region)
    error_message = "Valid values for var: aws_bedrock_cross_region are (global, us)."
  }
}

variable "aws_bedrock_use_case_for_model_access" {
  description = "Use case passed to Anthropic (not needed for non-Anthropic models)."
  type        = map(any)
  sensitive   = false
  default     = {}
}

variable "resource_name_prefix" {
  description = "String to prepend to all created resource names."
  type        = string
  sensitive   = false
}
