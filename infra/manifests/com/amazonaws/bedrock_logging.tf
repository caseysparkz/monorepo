/*
Bedrock

Enable Bedrock model invocation and log to S3.
*/

// Data ========================================================================
data "aws_iam_policy_document" "allow_bedrock_log_s3" {
  statement { // Allow bedrock to write logs to S3
    sid       = "AllowBedrockLogS3"
    effect    = "Allow"
    actions   = ["s3:PutObject*"]
    resources = ["${aws_s3_bucket.bedrock_logs.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.this.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:*:${data.aws_caller_identity.this.account_id}:*"]
    }
  }
}

// Modules =====================================================================

// Resources ===================================================================
resource "aws_s3_bucket" "bedrock_logs" { // trivy:ignore:AWS-0089
  bucket        = "${local.namespace}-s3-bucket-bedrocklogs"
  force_destroy = true

  lifecycle {
    ignore_changes = [
      tags["CreatorId"],
      tags["CreatorName"],
    ]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.bucket

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

resource "aws_s3_bucket_public_access_block" "bedrock_logs" {
  bucket                  = aws_s3_bucket.bedrock_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  skip_destroy            = true
}

resource "aws_s3_bucket_versioning" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = data.terraform_remote_state.this.outputs.aws_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.bucket
  policy = data.aws_iam_policy_document.allow_bedrock_log_s3.json
}

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  depends_on = [aws_s3_bucket_policy.bedrock_logs]

  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = true
    text_data_delivery_enabled      = true
    video_data_delivery_enabled     = true

    s3_config {
      bucket_name = aws_s3_bucket.bedrock_logs.id
      key_prefix  = "bedrock"
    }
  }
}
