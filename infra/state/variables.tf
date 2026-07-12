################################################################################
# Variables
#

# AWS ==========================================================================
variable "aws_region" {
  description = "AWS region to deploy to."
  type        = string
  sensitive   = false
  default     = "us-west-2"
}

# Misc. ========================================================================
variable "bucket_name" {
  description = "Name of the AWS bucket to create."
  type        = string
  sensitive   = false
  default     = "com.caseysparkz.tfstate"
}
