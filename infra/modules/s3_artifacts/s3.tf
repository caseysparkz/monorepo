################################################################################
# AWS S3
#

# Resources ====================================================================
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.root_domain}-artifacts"
  force_destroy = false
  tags = {
    Service = "s3"
    Project = "artifacts"
  }
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "artifacts" {
  depends_on = [aws_s3_bucket_ownership_controls.artifacts]
  bucket     = aws_s3_bucket.artifacts.id
  acl        = "private"
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}
