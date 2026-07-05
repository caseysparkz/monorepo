################################################################################
# Variables
#

variable "aws_region" {
  type        = string
  description = "AWS region to deploy to."
  sensitive   = false
  default     = "us-west-2"
}

variable "root_domain" {
  type        = string
  description = "Root domain of Terraform infrastructure."
  sensitive   = false
  default     = "caseysparkz.com"
}

variable "aws_kms_key_id" {
  description = "ID of the AWS KMS key used to encrypt assets."
  type        = string
  sensitive   = false
  default     = "de8cf575-e753-44b5-9331-fa1762775478"
}
