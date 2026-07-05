################################################################################
# Variables
#

# Misc. ========================================================================
variable "aws_region" {
  description = "Region to deploy the Terraformed resources."
  type        = string
  sensitive   = false
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create."
  type        = string
  sensitive   = false
  default     = "photos.caseysparkz.com"
}

variable "kms_key_id" {
  description = "ID of the AWS KMS key used to encrypt S3 artifacts."
  type        = string
  sensitive   = false
  default     = "de8cf575-e753-44b5-9331-fa1762775478"
}

variable "root_domain" {
  description = "Root domain of Terraform infrastructure."
  type        = string
  sensitive   = false
  default     = "caseysparkz.com"
}
