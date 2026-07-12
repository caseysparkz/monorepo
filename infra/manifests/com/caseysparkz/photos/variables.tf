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

variable "bucket_name_prefix" {
  description = "Name of the S3 bucket to create."
  type        = string
  sensitive   = false
  default     = "photos"
}
