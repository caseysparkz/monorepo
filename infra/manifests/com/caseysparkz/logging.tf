/* Global Logging */

// Data ========================================================================
data "aws_iam_policy_document" "s3_bucket_logging" {
  statement {
    sid     = "DenyUnencryptedAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logging.arn,
      "${aws_s3_bucket.logging.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SecureTransport"
      values   = [false]
    }
  }
}

// Resources ===================================================================
resource "aws_s3_bucket" "logging" { // trivy:ignore:AWS-0089
  bucket = "${local.namespace}-s3-bucket-logging"
  tags   = { Name = "${local.namespace}-s3-bucket-logging" }
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.bucket
  policy = data.aws_iam_policy_document.s3_bucket_logging.json
}

resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  bucket = aws_s3_bucket.logging.bucket

  rule {
    id     = "rule_01"
    status = "Enabled"

    filter {} // All objects

    transition { // Transition to infrequent access after one month
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition { // Transition to Glacier after three months
      days          = 90
      storage_class = "GLACIER"
    }

    expiration { days = 365 } // Delete logs after one year
  }
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

// Outputs =====================================================================
output "aws_s3_logging_bucket_id" {
  description = "ID of the global AWS S3 log bucket."
  value       = aws_s3_bucket.logging.id
  sensitive   = false
}
