################################################################################
# AWS IAM
#

# Data =========================================================================
data "aws_iam_policy_document" "lambda_iam_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_iam_policy" {
  statement {
    sid    = "AllowSesSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      aws_ses_domain_identity.root_domain.arn,
      aws_ses_email_identity.default_recipient.arn,
      aws_ses_email_identity.default_sender.arn
    ]
  }

  statement {
    sid       = "AllowKmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.aws_kms_key_arn]
  }

  statement {
    sid    = "AllowCreateLog"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# Resources ====================================================================
# IAM role ---------------------------------------------------------------------
resource "aws_iam_role" "lambda_contact_form" {
  name               = "${local.reverse_dns_subdomain_dir}-lambda-contact-form-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_role.json
}

# Policies ---------------------------------------------------------------------
resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "${local.reverse_dns_subdomain_dir}-lambda-contact-form-iam-policy"
  description = "Policy for Lambda to send emails via AWS SES, decrypt S3 artifacts, and log."
  policy      = data.aws_iam_policy_document.lambda_iam_policy.json
}

# Policy attachments -----------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_iam_policy" {
  role       = aws_iam_role.lambda_contact_form.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
