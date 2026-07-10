################################################################################
# Variables
#

# Misc. ========================================================================
variable "aws_region" {
  description = "Region to deploy AWS resources in."
  type        = string
  sensitive   = false
  default     = "us-west-2"
}
