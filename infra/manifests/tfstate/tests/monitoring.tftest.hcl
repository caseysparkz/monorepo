/* Monitoring pipeline: CloudTrail -> CloudWatch Logs -> alarms -> SNS, plus the EventBridge tamper path. */

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

override_resource {
  target          = aws_kms_key.monitoring
  override_during = plan
  values = {
    key_id = "22222222-2222-2222-2222-222222222222"
    arn    = "arn:aws:kms:us-west-2:111122223333:key/22222222-2222-2222-2222-222222222222"
  }
}

run "log_group_and_topic_are_encrypted" {
  command = plan

  assert {
    condition     = aws_kms_key.monitoring.enable_key_rotation == true
    error_message = "Monitoring key rotation must be enabled."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cloudtrail.kms_key_id == aws_kms_key.monitoring.arn
    error_message = "Log group must be encrypted with the monitoring key."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cloudtrail.retention_in_days == 90
    error_message = "Log group retention must be 90 days."
  }

  assert {
    condition     = aws_sns_topic.alerts.kms_master_key_id == aws_kms_key.monitoring.arn
    error_message = "Alert topic must be encrypted with the monitoring key."
  }

  assert {
    condition     = aws_sns_topic_subscription.alerts.protocol == "email" && aws_sns_topic_subscription.alerts.endpoint == "security@caseysparkz.com"
    error_message = "Alerts must be emailed to the owner."
  }
}

run "every_alarm_has_a_metric_filter_and_notifies_the_topic" {
  command = plan

  assert {
    condition = toset(keys(aws_cloudwatch_metric_alarm.this)) == toset([
      "access-denied",
      "alarm-tamper",
      "cloudtrail-tamper",
      "events-tamper",
      "kms-management",
      "logs-tamper",
      "s3-management",
      "sns-tamper",
      "state-read",
      "state-write",
    ])
    error_message = "Alarm set changed; update the README's alarm table and this test."
  }

  assert {
    condition     = toset(keys(aws_cloudwatch_log_metric_filter.this)) == toset(keys(aws_cloudwatch_metric_alarm.this))
    error_message = "Every alarm must have a matching metric filter."
  }

  assert {
    condition = alltrue([
      for k, a in aws_cloudwatch_metric_alarm.this :
      a.alarm_name == "global-terraform-state-alarm-${k}" &&
      a.namespace == "global-terraform-state" &&
      a.metric_name == k &&
      a.threshold == 1 &&
      a.comparison_operator == "GreaterThanOrEqualToThreshold" &&
      a.treat_missing_data == "notBreaching" &&
      toset(a.alarm_actions) == toset([aws_sns_topic.alerts.arn])
    ])
    error_message = "Each alarm must fire on one matching event and notify the alert topic."
  }

  assert {
    condition = alltrue([
      for k, f in aws_cloudwatch_log_metric_filter.this :
      f.log_group_name == aws_cloudwatch_log_group.cloudtrail.name &&
      one(f.metric_transformation).name == k &&
      one(f.metric_transformation).namespace == "global-terraform-state"
    ])
    error_message = "Each metric filter must read the trail's log group and publish the alarm's metric."
  }
}

run "filter_patterns_are_well_formed" {
  command = plan

  assert {
    condition = alltrue([
      for f in aws_cloudwatch_log_metric_filter.this :
      startswith(f.pattern, "{") && endswith(f.pattern, "}") && !can(regex("\\n|\\s{2,}", f.pattern))
    ])
    error_message = "Patterns must be single-line, whitespace-normalized JSON filter expressions."
  }

  assert {
    condition = alltrue([
      for f in aws_cloudwatch_log_metric_filter.this : length(f.pattern) <= 1024
    ])
    error_message = "CloudWatch Logs rejects filter patterns longer than 1024 characters."
  }

  assert {
    condition = alltrue([
      for f in aws_cloudwatch_log_metric_filter.this :
      length(regexall("\\(", f.pattern)) == length(regexall("\\)", f.pattern))
    ])
    error_message = "Pattern parentheses must balance."
  }
}

run "filter_patterns_target_the_right_resources" {
  command = plan

  assert {
    condition = alltrue([
      for k in ["state-read", "state-write"] :
      strcontains(aws_cloudwatch_log_metric_filter.this[k].pattern, "$.requestParameters.bucketName = \"${aws_s3_bucket.this.id}\"") &&
      strcontains(aws_cloudwatch_log_metric_filter.this[k].pattern, "$.requestParameters.key != \"*.tflock\"") &&
      strcontains(aws_cloudwatch_log_metric_filter.this[k].pattern, "$.errorCode NOT EXISTS")
    ])
    error_message = "State read/write alarms must watch successful non-lock operations on the state bucket."
  }

  assert {
    condition = alltrue([
      for k in ["access-denied", "s3-management"] :
      strcontains(aws_cloudwatch_log_metric_filter.this[k].pattern, "\"${aws_s3_bucket.this.id}\"") &&
      strcontains(aws_cloudwatch_log_metric_filter.this[k].pattern, "\"${aws_s3_bucket.logs.id}\"")
    ])
    error_message = "Access-denied and S3 management alarms must watch both buckets."
  }

  assert {
    condition = alltrue([
      strcontains(aws_cloudwatch_log_metric_filter.this["access-denied"].pattern, aws_kms_key.this.arn),
      strcontains(aws_cloudwatch_log_metric_filter.this["access-denied"].pattern, aws_kms_key.this.key_id),
      strcontains(aws_cloudwatch_log_metric_filter.this["access-denied"].pattern, aws_kms_alias.this.name),
    ])
    error_message = "Access-denied alarm must match every way of referencing the state key."
  }

  assert {
    condition = alltrue([
      strcontains(aws_cloudwatch_log_metric_filter.this["kms-management"].pattern, aws_kms_key.this.arn),
      strcontains(aws_cloudwatch_log_metric_filter.this["kms-management"].pattern, aws_kms_key.monitoring.arn),
      strcontains(aws_cloudwatch_log_metric_filter.this["kms-management"].pattern, aws_kms_alias.monitoring.name),
    ])
    error_message = "KMS management alarm must watch the state and monitoring keys."
  }

  assert {
    condition = alltrue([
      for op in ["Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncrypt"] :
      strcontains(aws_cloudwatch_log_metric_filter.this["kms-management"].pattern, "$.eventName != \"${op}\"")
    ])
    error_message = "KMS management alarm must ignore routine cryptographic operations."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_log_metric_filter.this["cloudtrail-tamper"].pattern, aws_cloudtrail.this.name)
    error_message = "CloudTrail tamper alarm must watch this trail."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_log_metric_filter.this["logs-tamper"].pattern, aws_cloudwatch_log_group.cloudtrail.name)
    error_message = "Logs tamper alarm must watch the trail's log group."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_log_metric_filter.this["alarm-tamper"].pattern, "global-terraform-state-alarm-*")
    error_message = "Alarm tamper alarm must match the alarm name prefix."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_log_metric_filter.this["sns-tamper"].pattern, aws_sns_topic.alerts.arn)
    error_message = "SNS tamper alarm must watch the alert topic."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_log_metric_filter.this["events-tamper"].pattern, aws_cloudwatch_event_rule.tamper.name)
    error_message = "Events tamper alarm must watch the EventBridge rule."
  }
}

run "eventbridge_rule_covers_each_monitored_service" {
  command = plan

  assert {
    condition     = toset(jsondecode(aws_cloudwatch_event_rule.tamper.event_pattern)["detail-type"]) == toset(["AWS API Call via CloudTrail"])
    error_message = "Tamper rule must match CloudTrail API calls."
  }

  assert {
    condition = toset(flatten([
      for clause in jsondecode(aws_cloudwatch_event_rule.tamper.event_pattern).detail["$or"] : clause.eventSource
      ])) == toset([
      "cloudtrail.amazonaws.com",
      "events.amazonaws.com",
      "kms.amazonaws.com",
      "logs.amazonaws.com",
      "monitoring.amazonaws.com",
      "sns.amazonaws.com",
    ])
    error_message = "Tamper rule must cover the trail, log group, alarms, topic, rule, and monitoring key."
  }

  assert {
    condition = alltrue([
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_cloudtrail.this.name),
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_cloudwatch_log_group.cloudtrail.name),
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_sns_topic.alerts.arn),
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_kms_key.monitoring.arn),
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_kms_key.monitoring.key_id),
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_kms_alias.monitoring.name),
      strcontains(aws_cloudwatch_event_rule.tamper.event_pattern, aws_cloudwatch_event_rule.tamper.name),
    ])
    error_message = "Tamper rule must reference each monitored resource."
  }

  assert {
    condition     = aws_cloudwatch_event_target.tamper.rule == aws_cloudwatch_event_rule.tamper.name && aws_cloudwatch_event_target.tamper.arn == aws_sns_topic.alerts.arn
    error_message = "Tamper rule must target the alert topic."
  }
}

run "topic_policy_limits_publishers_and_administrators" {
  command = plan

  variables {
    admin_principal_arns = ["arn:aws:iam::111122223333:role/admin"]
  }

  assert {
    condition = toset([for s in data.aws_iam_policy_document.sns_alerts.statement : s.sid]) == toset([
      "AllowAlarmPublishing",
      "AllowEventPublishing",
      "DenyTopicAdministrationToNonAdmins",
    ])
    error_message = "Unexpected set of topic policy statements."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.sns_alerts.statement :
      toset(s.resources) == toset([aws_sns_topic.alerts.arn])
    ])
    error_message = "Every topic policy statement must be scoped to the alert topic."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.sns_alerts.statement :
      toset(one([for c in s.condition : c if c.variable == "aws:SourceArn"]).values) == toset(["arn:aws:cloudwatch:us-west-2:111122223333:alarm:global-terraform-state-alarm-*"])
      if s.sid == "AllowAlarmPublishing"
    ])
    error_message = "CloudWatch may only publish on behalf of this manifest's alarms."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.sns_alerts.statement :
      toset(one(s.condition).values) == toset(["arn:aws:events:us-west-2:111122223333:rule/${aws_cloudwatch_event_rule.tamper.name}"])
      if s.sid == "AllowEventPublishing"
    ])
    error_message = "EventBridge may only publish on behalf of the tamper rule."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.sns_alerts.statement :
      toset(one(s.condition).values) == toset(var.admin_principal_arns) &&
      length(setintersection(s.actions, ["sns:DeleteTopic", "sns:SetTopicAttributes", "sns:Subscribe"])) == 3
      if s.sid == "DenyTopicAdministrationToNonAdmins"
    ])
    error_message = "Only admins may administer the alert topic."
  }
}

run "monitoring_key_policy_is_scoped_to_its_consumers" {
  command = plan

  variables {
    admin_principal_arns = ["arn:aws:iam::111122223333:role/admin"]
  }

  assert {
    condition = toset([for s in data.aws_iam_policy_document.kms_key_monitoring.statement : s.sid]) == toset([
      "AllowAlertPublishing",
      "AllowCloudWatchLogsEncryption",
      "AllowKeyAdministration",
      "AllowKeyMetadataRead",
      "AllowKeyUsageViaSNS",
    ])
    error_message = "Unexpected set of monitoring key policy statements."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key_monitoring.statement :
      toset(one(s.principals).identifiers) == toset(var.admin_principal_arns)
      if contains(["AllowKeyAdministration", "AllowKeyUsageViaSNS"], s.sid)
    ])
    error_message = "Key administration and SNS usage must be limited to admins."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key_monitoring.statement :
      toset(one(s.condition).values) == toset(["sns.us-west-2.amazonaws.com"])
      if s.sid == "AllowKeyUsageViaSNS"
    ])
    error_message = "Admin key usage must be limited to SNS in this region."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key_monitoring.statement :
      toset(one(s.principals).identifiers) == toset(["logs.us-west-2.amazonaws.com"]) &&
      toset(one(s.condition).values) == toset(["arn:aws:logs:us-west-2:111122223333:log-group:${aws_cloudwatch_log_group.cloudtrail.name}"])
      if s.sid == "AllowCloudWatchLogsEncryption"
    ])
    error_message = "CloudWatch Logs may only use the key for the trail's log group."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.kms_key_monitoring.statement :
      toset(one(s.principals).identifiers) == toset(["cloudwatch.amazonaws.com", "events.amazonaws.com"])
      if s.sid == "AllowAlertPublishing"
    ])
    error_message = "Only CloudWatch and EventBridge may use the key to publish alerts."
  }
}

run "cloudtrail_role_is_least_privilege" {
  command = plan

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.cloudtrail_logs_assume_role.statement :
      toset(one(s.principals).identifiers) == toset(["cloudtrail.amazonaws.com"]) &&
      toset(one(s.condition).values) == toset(["arn:aws:cloudtrail:us-west-2:111122223333:trail/${aws_cloudtrail.this.name}"])
    ])
    error_message = "Only this trail may assume the CloudTrail logs role."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.cloudtrail_logs.statement :
      toset(s.actions) == toset(["logs:CreateLogStream", "logs:PutLogEvents"]) &&
      toset(s.resources) == toset(["${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:*"])
    ])
    error_message = "CloudTrail logs role must only write streams in the trail's log group."
  }
}

run "readonly_policy_exempts_only_read_actions" {
  command = plan

  assert {
    condition = alltrue(flatten([
      for s in data.aws_iam_policy_document.monitoring_readonly.statement : [
        for a in s.not_actions :
        can(regex(":(Describe\\*|Get\\*|List\\*|LookupEvents|FilterLogEvents)$", a))
      ]
    ]))
    error_message = "A mutating action was exempted from DenyMonitoringMutation."
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.monitoring_readonly.statement :
      s.effect == "Deny" && alltrue([
        for arn in [
          aws_cloudwatch_log_group.cloudtrail.arn,
          "${aws_cloudwatch_log_group.cloudtrail.arn}:*",
          aws_sns_topic.alerts.arn,
          "${aws_sns_topic.alerts.arn}:*",
          aws_iam_role.cloudtrail_logs.arn,
          aws_iam_policy.monitoring_readonly.arn,
          "arn:aws:cloudtrail:us-west-2:111122223333:trail/${aws_cloudtrail.this.name}",
          "arn:aws:cloudwatch:us-west-2:111122223333:alarm:global-terraform-state-alarm-*",
          "arn:aws:events:us-west-2:111122223333:rule/${aws_cloudwatch_event_rule.tamper.name}",
        ] : contains(s.resources, arn)
      ])
    ])
    error_message = "DenyMonitoringMutation must cover every monitoring resource."
  }
}

run "readonly_policy_attaches_to_default_non_admin_roles" {
  command = plan

  assert {
    condition = toset(keys(aws_iam_role_policy_attachment.monitoring_readonly)) == toset([
      "prod-iam-githubactions-iam-role-ghaadmin",
      "prod-iam-githubactions-iam-role-ghareadonly",
    ])
    error_message = "Read-only policy must attach to the non-admin GitHub Actions roles only."
  }
}

run "readonly_policy_skips_admins_and_unattachable_principals" {
  command = plan

  variables {
    admin_principal_arns = ["arn:aws:iam::111122223333:role/admin"]
    writer_principal_arns = [
      "arn:aws:iam::111122223333:role/admin",
      "arn:aws:iam::111122223333:role/some/path/writer",
      "arn:aws:iam::111122223333:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_Dev_0123456789abcdef",
    ]
    reader_principal_arns = [
      "arn:aws:iam::111122223333:role/reader",
      "arn:aws:iam::111122223333:user/human",
      "arn:aws:sts::111122223333:assumed-role/session-role/session",
    ]
  }

  assert {
    condition     = toset(keys(aws_iam_role_policy_attachment.monitoring_readonly)) == toset(["writer", "reader"])
    error_message = "Must attach by role name to non-admin, non-SSO roles only."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.monitoring_readonly["writer"].role == "writer"
    error_message = "Role paths must be stripped when attaching the policy."
  }
}
