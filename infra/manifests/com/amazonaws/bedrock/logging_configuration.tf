/* Bedrock model invocation logging configuration. */

// Data ========================================================================
data "aws_iam_policy_document" "bedrock_logging_bucket_policy" {
  statement { // AllowBedrockLogsWrite
    sid       = "AmazonBedrockLogsWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.bedrock_logs.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${var.aws_region}:${local.aws_account_id}:*"]
    }
  }
}

data "aws_iam_policy_document" "allow_bedrock_sts_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${var.aws_region}:${local.aws_account_id}:*"]
    }
  }
}

data "aws_iam_policy_document" "allow_bedrock_log_cloudwatch" {
  statement {
    sid    = "AmazonBedrockModelInvocationCWDeliveryRole"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${local.aws_account_id}:log-group:${aws_cloudwatch_log_group.bedrock_logs.name}:*"
    ]
  }
}

// Modules =====================================================================

// Resources ===================================================================
// IAM -------------------------------------------------------------------------
resource "aws_iam_role" "bedrock_logging" {
  name               = "${local.namespace}-iam-role-bedrocklogging"
  assume_role_policy = data.aws_iam_policy_document.allow_bedrock_sts_assume_role.json
  description        = "Allow Bedrock to log to CloudWatch."
  path               = "/system/"
  tags               = { Name = "${local.namespace}-iam-role" }
}

resource "aws_iam_role_policy" "bedrock_logging" {
  role   = aws_iam_role.bedrock_logging.name
  policy = data.aws_iam_policy_document.allow_bedrock_log_cloudwatch.json
}

// S3 --------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "bedrock_logs" {
  kms_key_id        = data.terraform_remote_state.this.outputs.aws_kms_key_arn
  retention_in_days = 90
  skip_destroy      = false
  tags              = { Name = "${local.namespace}-cloudwatch-log-group" }
}

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
  policy = data.aws_iam_policy_document.bedrock_logging_bucket_policy.json
}

// Bedrock ---------------------------------------------------------------------
resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  depends_on = [aws_s3_bucket_policy.bedrock_logs]

  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = true
    text_data_delivery_enabled      = true
    video_data_delivery_enabled     = true

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock_logs.name
      role_arn       = aws_iam_role.bedrock_logging.arn
    }

    s3_config {
      bucket_name = aws_s3_bucket.bedrock_logs.id
      //key_prefix  = "bedrock"
    }
  }
}
