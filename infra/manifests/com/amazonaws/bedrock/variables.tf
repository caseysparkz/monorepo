/* Variables */

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

variable "aws_bedrock_model_throughput" {
  description = "Provisioned throughput of the Bedrock model."
  type        = number
  default     = 1
  sensitive   = false
}
