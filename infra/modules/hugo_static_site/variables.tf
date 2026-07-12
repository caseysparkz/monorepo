################################################################################
# Variables.
#

# Lambda =======================================================================
variable "artifact_bucket_id" {
  description = "ID of the S3 bucket in which lambda functions are kept."
  type        = string
  sensitive   = false
}

variable "js_contact_form_template_path" {
  description = "String contaning the Javascript for the contact form Lambda backend."
  type        = string
  sensitive   = false
}

# KMS ==========================================================================
variable "aws_kms_key_arn" {
  description = "ARN of the AWS KMS key used to encrypt the Lambda function in S3."
  type        = string
  sensitive   = false
}

# Misc. ========================================================================
variable "root_domain" {
  description = "Root domain of Terraform infrastructure."
  type        = string
  sensitive   = false
}

variable "subdomain" {
  description = "Subdomain of Terraform infrastructure."
  type        = string
  sensitive   = false
}

variable "site_title" {
  description = "Title of the website."
  type        = string
  sensitive   = false
}

variable "hugo_dir" {
  description = "Absolute path of the Hugo directory."
  type        = string
  sensitive   = false

  validation {
    condition     = fileexists("${var.hugo_dir}/hugo.yml")
    error_message = "${var.hugo_dir}/hugo.yml does not exist."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  sensitive   = false
}
