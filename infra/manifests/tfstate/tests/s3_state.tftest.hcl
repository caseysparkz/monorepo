/* State bucket: hardening, encryption, and bucket policy. */

mock_provider "aws" {
  override_during = plan
  source          = "./tests/mocks"
}

override_resource {
  target          = aws_s3_bucket.this
  override_during = plan
  values = {
    id  = "com.caseysparkz.tfstate"
    arn = "arn:aws:s3:::com.caseysparkz.tfstate"
  }
}

override_resource {
  target          = aws_s3_bucket.logs
  override_during = plan
  values = {
    id  = "global-terraform-state-s3-bucket-logs"
    arn = "arn:aws:s3:::global-terraform-state-s3-bucket-logs"
  }
}

override_resource {
  target          = aws_kms_key.this
  override_during = plan
  values = {
    key_id = "11111111-1111-1111-1111-111111111111"
    arn    = "arn:aws:kms:us-west-2:111122223333:key/11111111-1111-1111-1111-111111111111"
  }
}

variables {
  admin_principal_arns  = ["arn:aws:iam::111122223333:role/admin"]
  writer_principal_arns = ["arn:aws:iam::111122223333:role/writer"]
  reader_principal_arns = ["arn:aws:iam::111122223333:role/reader"]
}

run "bucket_is_hardened" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "com.caseysparkz.tfstate"
    error_message = "State bucket name must match the backend block in providers.tf."
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "State bucket must not be force-destroyable."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "State bucket versioning must be enabled."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "State bucket must disable ACLs with BucketOwnerEnforced."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All four public access block settings must be enabled."
  }
}

run "bucket_is_encrypted_with_its_kms_key" {
  command = plan

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled == true
    error_message = "S3 bucket keys must be enabled."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "State bucket must use SSE-KMS."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == aws_kms_key.this.arn
    error_message = "State bucket must be encrypted with aws_kms_key.this."
  }
}

run "access_logs_go_to_the_log_bucket" {
  command = plan

  assert {
    condition     = aws_s3_bucket_logging.this.target_bucket == aws_s3_bucket.logs.id
    error_message = "State bucket access logs must be delivered to the log bucket."
  }

  assert {
    condition     = aws_s3_bucket_logging.this.target_prefix == "s3-access/"
    error_message = "Access log prefix must match the AllowS3ServerAccessLogDelivery resource."
  }

  assert {
    condition     = one(one(aws_s3_bucket_logging.this.target_object_key_format).partitioned_prefix).partition_date_source == "EventTime"
    error_message = "Access logs must be partitioned by event time."
  }
}

run "policy_contains_only_deny_statements" {
  command = plan

  assert {
    condition = toset([for s in data.aws_iam_policy_document.s3_bucket.statement : s.sid]) == toset([
      "DenyBucketAdministrationToNonAdmins",
      "DenyInsecureTransport",
      "DenyLockWritesToNonReaders",
      "DenyStateReadsToNonReaders",
      "DenyStateWritesToNonWriters",
    ])
    error_message = "Unexpected set of bucket policy statements."
  }

  assert {
    condition     = alltrue([for s in data.aws_iam_policy_document.s3_bucket.statement : s.effect == "Deny"])
    error_message = "State bucket policy must be deny-only; access is granted by IAM."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      one(s.principals).type == "*" && toset(one(s.principals).identifiers) == toset(["*"])
    ])
    error_message = "Each deny statement must apply to all principals."
  }
}

run "policy_denies_insecure_transport" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      toset(s.actions) == toset(["s3:*"]) &&
      toset(s.resources) == toset([aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]) &&
      one(s.condition).test == "Bool" &&
      one(s.condition).variable == "aws:SecureTransport" &&
      toset(one(s.condition).values) == toset(["false"])
      if s.sid == "DenyInsecureTransport"
    ])
    error_message = "DenyInsecureTransport must cover the bucket and its objects."
  }
}

run "readers_and_writers_may_read_state_and_write_locks" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      one(s.condition).test == "ArnNotEquals" &&
      one(s.condition).variable == "aws:PrincipalArn" &&
      toset(one(s.condition).values) == toset(concat(var.reader_principal_arns, var.writer_principal_arns))
      if contains(["DenyStateReadsToNonReaders", "DenyLockWritesToNonReaders"], s.sid)
    ])
    error_message = "State reads and lock writes must be restricted to readers and writers."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      toset(s.resources) == toset(["${aws_s3_bucket.this.arn}/*.tflock"])
      if s.sid == "DenyLockWritesToNonReaders"
    ])
    error_message = "Lock write exemption must be scoped to *.tflock objects."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      toset(s.actions) == toset(["s3:DeleteObject", "s3:PutObject"])
      if s.sid == "DenyLockWritesToNonReaders"
    ])
    error_message = "Lock statement must cover exactly the actions the S3 lockfile needs."
  }
}

run "only_writers_may_write_state" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      toset(one(s.condition).values) == toset(var.writer_principal_arns)
      if s.sid == "DenyStateWritesToNonWriters"
    ])
    error_message = "State writes must be restricted to writers (readers excluded)."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      toset(s.not_resources) == toset(["${aws_s3_bucket.this.arn}/*.tflock"])
      if s.sid == "DenyStateWritesToNonWriters"
    ])
    error_message = "State write denial must apply to everything except lockfiles."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      length(setintersection(s.actions, ["s3:DeleteObject", "s3:DeleteObjectVersion", "s3:PutObject", "s3:RestoreObject"])) == 4
      if s.sid == "DenyStateWritesToNonWriters"
    ])
    error_message = "State write denial must cover put, delete, delete-version, and restore."
  }
}

run "only_admins_may_administer_the_bucket" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      toset(one(s.condition).values) == toset(var.admin_principal_arns) &&
      toset(s.resources) == toset([aws_s3_bucket.this.arn])
      if s.sid == "DenyBucketAdministrationToNonAdmins"
    ])
    error_message = "Bucket administration must be restricted to admins."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_bucket.statement :
      length(setintersection(s.actions, [
        "s3:DeleteBucket",
        "s3:DeleteBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketVersioning",
        "s3:PutEncryptionConfiguration",
      ])) == 6
      if s.sid == "DenyBucketAdministrationToNonAdmins"
    ])
    error_message = "Admin-only actions must include the bucket's critical protections."
  }
}

run "outputs_identify_the_bucket" {
  command = plan

  assert {
    condition     = output.aws_s3_bucket_name == "com.caseysparkz.tfstate"
    error_message = "aws_s3_bucket_name output is wrong."
  }

  assert {
    condition     = output.aws_s3_bucket_uri == "s3://com.caseysparkz.tfstate/"
    error_message = "aws_s3_bucket_uri output is wrong."
  }
}
