################################################################################
# Global Logging
#

# Data =========================================================================

# Resources ====================================================================
resource "aws_s3_bucket" "logging" { #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket = "${local.namespace}-s3-bucket-logging"
  tags   = { Name = "${local.namespace}-s3-bucket-logging" }
}

resource "aws_s3_bucket_versioning" "logging" {
  bucket = aws_s3_bucket.logging.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  bucket = aws_s3_bucket.logging.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logging" {
  bucket                  = aws_s3_bucket.logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs ======================================================================
output "aws_s3_logging_bucket_id" {
  description = "ID of the global AWS S3 log bucket."
  value       = aws_s3_bucket.logging.id
  sensitive   = false
}
