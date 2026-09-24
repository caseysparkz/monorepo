/* Variables */

variable "enabled" {
  description = "Whether or not Bedrock is enabled on my account."
  type        = bool
  sensitive   = false
  default     = false
}

variable "aws_region" {
  description = "AWS region to deploy resources to."
  type        = string
  sensitive   = false
  default     = "us-west-2"
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
