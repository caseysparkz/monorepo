################################################################################
# Main
#

locals {
  environment = "prod"
  project     = "tfstate"
  application = "tfstate"
  namespace   = "${local.environment}-${local.project}-${local.application}"
  common_tags = {
    ManagedBy = "terraform"
    Namespace = local.namespace
  }
}

# Resources ====================================================================
resource "aws_resourcegroups_group" "this" {
  name = "${local.namespace}-rg"
  tags = { Name = "${local.namespace}-rg" }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        for key, value in local.common_tags :
        {
          Key    = key
          Values = [value]
        }
      ]
    })
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS key for terraform state S3 bucket objects."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = { Name = "${local.namespace}-kms-key" }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${replace(var.bucket_name, ".", "/")}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name # trivy:ignore:AWS-0320
  force_destroy = false
  tags          = { Name = "${local.namespace}-s3-state" }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = "prod-caseysparkz-root-s3-bucket-logging"
  target_prefix = "tfstate"
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = aws_s3_bucket.this.id
  acl        = "private"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Outputs ======================================================================
output "aws_s3_bucket_name" {
  description = "FQDN of the S3 bucket (as expected by the Terraform backend config)."
  value       = aws_s3_bucket.this.id
}

output "aws_s3_bucket_uri" {
  description = "URI of the S3 bucket (as expected by the AWS CLI)."
  value       = "s3://${aws_s3_bucket.this.id}/"
}
