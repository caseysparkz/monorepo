###############################################################################
# KMS Tests
#

## Variables ==================================================================
variables {
  root_domain = "test.com"
}

## Tests ======================================================================
run "aws_kms_key_artifacts" {
  assert {
    condition     = can(regex("^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){2}-[[:xdigit:]]{12}$", aws_kms_key.artifacts.key_id))
    error_message = "Invalid AWS KMS key ID."
  }
  assert {
    condition     = startwith("arn:aws:kms:", aws_kms_key.artifacts.arn)
    error_message = "Invalid AWS KMS key ARN."
  }
}
