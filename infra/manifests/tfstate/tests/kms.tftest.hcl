/* State KMS key and its key policy. */

mock_provider "aws" {
  override_during = plan
  source          = "./tests/mocks"
}

variables {
  admin_principal_arns  = ["arn:aws:iam::111122223333:role/admin"]
  writer_principal_arns = ["arn:aws:iam::111122223333:role/writer"]
  reader_principal_arns = ["arn:aws:iam::111122223333:role/reader"]
}

run "key_is_rotated" {
  command = plan

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == true
    error_message = "State key rotation must be enabled."
  }

  assert {
    condition     = aws_kms_alias.this.name == "alias/global-terraform-state-kms-key"
    error_message = "State key alias changed; the access-denied alarm depends on it."
  }
}

run "policy_separates_administration_from_usage" {
  command = plan

  assert {
    condition = toset([for s in data.aws_iam_policy_document.kms_key.statement : s.sid]) == toset([
      "KeyAdministration",
      "KeyMetadataRead",
      "KeyUsageViaS3",
    ])
    error_message = "Unexpected set of KMS key policy statements."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key.statement :
      toset(one(s.principals).identifiers) == toset(var.admin_principal_arns)
      if s.sid == "KeyAdministration"
    ])
    error_message = "Key administration must be limited to admins."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key.statement :
      toset(one(s.principals).identifiers) == toset(concat(var.reader_principal_arns, var.writer_principal_arns))
      if contains(["KeyMetadataRead", "KeyUsageViaS3"], s.sid)
    ])
    error_message = "Key usage and metadata reads must be limited to state principals."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key.statement :
      length(setintersection(s.actions, ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"])) == 0
      if s.sid == "KeyAdministration"
    ])
    error_message = "Administering the key must not grant cryptographic use of it."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key.statement :
      length(setintersection(s.actions, ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"])) == 0
      if s.sid == "KeyMetadataRead"
    ])
    error_message = "Metadata reads must not grant cryptographic use of the key."
  }
}

run "usage_is_limited_to_s3_in_this_account" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key.statement :
      toset(one([for c in s.condition : c if c.variable == "kms:ViaService"]).values) == toset(["s3.us-west-2.amazonaws.com"]) &&
      toset(one([for c in s.condition : c if c.variable == "kms:CallerAccount"]).values) == toset(["111122223333"])
      if s.sid == "KeyUsageViaS3"
    ])
    error_message = "Key usage must be limited to S3 in this region and account."
  }
}
