################################################################################
# Variables
#

variable "aws_region" {
  type        = string
  description = "AWS region to deploy to."
  sensitive   = false
  default     = "us-west-2"
}
