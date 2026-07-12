################################################################################
# Variables
#

# Misc. ========================================================================
variable "root_domain" {
  description = "Root domain of the deployed infrastructure."
  type        = string
  sensitive   = false
}

variable "kms_key_arn" {
  description = "ID of the AWS KMS key used to encrypt S3 artifacts."
  type        = string
  sensitive   = false
}
