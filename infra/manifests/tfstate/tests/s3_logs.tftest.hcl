/* Log bucket and CloudTrail trail. */

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

variables {
  admin_principal_arns  = ["arn:aws:iam::111122223333:role/admin"]
  writer_principal_arns = ["arn:aws:iam::111122223333:role/writer"]
  reader_principal_arns = ["arn:aws:iam::111122223333:role/reader"]
}

run "bucket_is_hardened" {
  command = plan

  assert {
    condition     = aws_s3_bucket.logs.force_destroy == false
    error_message = "Log bucket must not be force-destroyable."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.logs.versioning_configuration).status == "Enabled"
    error_message = "Log bucket versioning must be enabled."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.logs.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "Log bucket must disable ACLs with BucketOwnerEnforced."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.logs.block_public_acls,
      aws_s3_bucket_public_access_block.logs.block_public_policy,
      aws_s3_bucket_public_access_block.logs.ignore_public_acls,
      aws_s3_bucket_public_access_block.logs.restrict_public_buckets,
    ])
    error_message = "All four public access block settings must be enabled."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.logs.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "S3 access log delivery requires SSE-S3 on the log bucket."
  }
}

// Terraform 1.16.6 panics when reporting a failed top-level `==` on these values, so each is wrapped in alltrue().
run "lifecycle_retains_logs_for_one_year" {
  command = plan

  assert {
    condition     = alltrue([one(aws_s3_bucket_lifecycle_configuration.logs.rule).status == "Enabled"])
    error_message = "Lifecycle rule must be enabled."
  }

  assert {
    condition     = alltrue([one([for t in one(aws_s3_bucket_lifecycle_configuration.logs.rule).transition : t.days if t.storage_class == "STANDARD_IA"]) == 30])
    error_message = "Logs must move to STANDARD_IA at 30 days."
  }

  assert {
    condition     = alltrue([one([for t in one(aws_s3_bucket_lifecycle_configuration.logs.rule).transition : t.days if t.storage_class == "GLACIER"]) == 90])
    error_message = "Logs must move to GLACIER at 90 days."
  }

  assert {
    condition     = alltrue([one(one(aws_s3_bucket_lifecycle_configuration.logs.rule).expiration).days == 365])
    error_message = "Logs must expire after one year."
  }

  assert {
    condition     = alltrue([one(one(aws_s3_bucket_lifecycle_configuration.logs.rule).noncurrent_version_expiration).noncurrent_days == 30])
    error_message = "Noncurrent log versions must expire after 30 days."
  }

  assert {
    condition     = alltrue([one(one(aws_s3_bucket_lifecycle_configuration.logs.rule).abort_incomplete_multipart_upload).days_after_initiation == 7])
    error_message = "Incomplete multipart uploads must be aborted after 7 days."
  }
}

run "policy_has_expected_statements" {
  command = plan

  assert {
    condition = toset([for s in data.aws_iam_policy_document.s3_logs.statement : s.sid]) == toset([
      "AllowCloudTrailAclCheck",
      "AllowCloudTrailLogDelivery",
      "AllowS3ServerAccessLogDelivery",
      "DenyBucketAdministrationToNonAdmins",
      "DenyInsecureTransport",
      "DenyLogListingToNonStatePrincipals",
      "DenyLogReadsToNonAdmins",
      "DenyLogTamperingByPrincipals",
    ])
    error_message = "Unexpected set of log bucket policy statements."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      one(s.principals).type == "Service" if s.effect == "Allow"
    ])
    error_message = "Only AWS service principals may be granted access to the log bucket."
  }
}

run "log_delivery_is_scoped_to_its_source" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      toset(s.resources) == toset(["${aws_s3_bucket.logs.arn}/${aws_s3_bucket_logging.this.target_prefix}*"]) &&
      toset(one([for c in s.condition : c if c.variable == "aws:SourceArn"]).values) == toset([aws_s3_bucket.this.arn]) &&
      toset(one([for c in s.condition : c if c.variable == "aws:SourceAccount"]).values) == toset(["111122223333"])
      if s.sid == "AllowS3ServerAccessLogDelivery"
    ])
    error_message = "S3 log delivery must be limited to the state bucket's source and log prefix."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      toset(s.resources) == toset(["${aws_s3_bucket.logs.arn}/${aws_cloudtrail.this.s3_key_prefix}/AWSLogs/111122223333/*"]) &&
      toset(one([for c in s.condition : c if c.variable == "aws:SourceArn"]).values) == toset(["arn:aws:cloudtrail:us-west-2:111122223333:trail/${aws_cloudtrail.this.name}"]) &&
      toset(one([for c in s.condition : c if c.variable == "s3:x-amz-acl"]).values) == toset(["bucket-owner-full-control"])
      if s.sid == "AllowCloudTrailLogDelivery"
    ])
    error_message = "CloudTrail delivery must be limited to this trail and its key prefix."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      toset(s.actions) == toset(["s3:GetBucketAcl"]) &&
      toset(s.resources) == toset([aws_s3_bucket.logs.arn]) &&
      toset(one(s.condition).values) == toset(["arn:aws:cloudtrail:us-west-2:111122223333:trail/${aws_cloudtrail.this.name}"])
      if s.sid == "AllowCloudTrailAclCheck"
    ])
    error_message = "CloudTrail ACL check must be limited to this trail."
  }
}

run "logs_are_protected_from_principals" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      s.effect == "Deny" &&
      one(s.condition).variable == "aws:PrincipalIsAWSService" &&
      toset(one(s.condition).values) == toset(["false"]) &&
      length(setintersection(s.actions, ["s3:DeleteObject", "s3:DeleteObjectVersion", "s3:PutObject"])) == 3
      if s.sid == "DenyLogTamperingByPrincipals"
    ])
    error_message = "No IAM principal may write or delete logs."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      toset(one(s.condition).values) == toset(var.admin_principal_arns)
      if s.sid == "DenyLogReadsToNonAdmins"
    ])
    error_message = "Only admins may read logs."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.s3_logs.statement :
      toset(one(s.condition).values) == toset(concat(var.admin_principal_arns, var.writer_principal_arns, var.reader_principal_arns))
      if s.sid == "DenyLogListingToNonStatePrincipals"
    ])
    error_message = "Listing must be limited to admins and state principals (needed by terraform plan)."
  }
}

run "trail_is_tamper_evident_and_delivers_to_cloudwatch" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.name == "global-terraform-state-cloudtrail"
    error_message = "Trail name changed; alarm patterns and policies depend on it."
  }

  assert {
    condition     = aws_cloudtrail.this.enable_log_file_validation == true
    error_message = "Log file validation must be enabled."
  }

  assert {
    condition     = aws_cloudtrail.this.s3_bucket_name == aws_s3_bucket.logs.id
    error_message = "Trail must deliver to the log bucket."
  }

  assert {
    condition     = aws_cloudtrail.this.cloud_watch_logs_group_arn == "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    error_message = "Trail must deliver to the CloudTrail log group."
  }

  assert {
    condition     = aws_cloudtrail.this.cloud_watch_logs_role_arn == aws_iam_role.cloudtrail_logs.arn
    error_message = "Trail must use the CloudTrail logs role."
  }
}

run "trail_records_management_and_state_object_events" {
  command = plan

  assert {
    condition     = toset([for s in aws_cloudtrail.this.advanced_event_selector : s.name]) == toset(["Management events", "State bucket object events"])
    error_message = "Trail must have exactly the management and state-object selectors."
  }

  assert {
    condition = alltrue([
      for s in aws_cloudtrail.this.advanced_event_selector :
      toset(one(s.field_selector).equals) == toset(["Management"])
      if s.name == "Management events"
    ])
    error_message = "Trail must record management events."
  }

  assert {
    condition = alltrue(flatten([
      for s in aws_cloudtrail.this.advanced_event_selector : [
        for f in s.field_selector :
        toset(f.starts_with) == toset(["${aws_s3_bucket.this.arn}/"])
        if f.field == "resources.ARN"
      ]
    ]))
    error_message = "Data events must be scoped to objects in the state bucket."
  }
}

run "output_identifies_the_log_bucket" {
  command = plan

  assert {
    condition     = output.aws_s3_logs_bucket_name == "global-terraform-state-s3-bucket-logs"
    error_message = "aws_s3_logs_bucket_name output is wrong."
  }
}
