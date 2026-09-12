/* Variables */

variable "aws_region" {
  description = "AWS region to deploy resources to."
  type        = string
  sensitive   = false
  default     = "us-west-2"
}

variable "aws_bedrock_foundation_model_name" {
  description = "Bedrock foundation model to deploy."
  type        = string
  sensitive   = false
  default     = "Claude Fable 5.1"
}
