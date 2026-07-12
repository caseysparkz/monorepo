################################################################################
# AWS Lambda
#

# Data =========================================================================
data "archive_file" "lambda_contact_form" { # Zipfile for Lambda artifact.
  type        = "zip"
  source_file = "${path.module}/lambda_contact_form.py"
  output_path = "/tmp/${var.root_domain}_contact_form.zip"
}

# Resources ====================================================================
resource "aws_lambda_function" "contact_form" {
  depends_on       = [aws_s3_object.lambda_contact_form]
  description      = "Python function to send an email via AWS SES."
  function_name    = replace("${var.subdomain}-contact_form", ".", "-")
  s3_bucket        = var.artifact_bucket_id
  s3_key           = aws_s3_object.lambda_contact_form.key
  runtime          = "python3.14"
  handler          = "lambda_contact_form.lambda_handler"
  source_code_hash = data.archive_file.lambda_contact_form.output_base64sha256
  role             = aws_iam_role.lambda_contact_form.arn

  tracing_config { mode = "Active" }

  environment {
    variables = {
      DEFAULT_RECIPIENT = local.email_headers["default_recipient"]
      DEFAULT_SENDER    = local.email_headers["default_sender"]
    }
  }
}

resource "aws_lambda_function_url" "contact_form" {
  function_name      = aws_lambda_function.contact_form.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins = [
      "https://${var.root_domain}",
      "https://${var.subdomain}",
    ]
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
  }
}

# Outputs ======================================================================
output "aws_lambda_function_invoke_arn" {
  description = "Invocation URL for the Lambda function."
  value       = aws_lambda_function.contact_form.invoke_arn
  sensitive   = false
}

output "aws_lambda_function_invoke_url" {
  description = "Invocation URL for the Lambda function."
  value       = aws_lambda_function_url.contact_form.function_url
  sensitive   = false
}
