/* Mock AWS provider defaults: well-formed values that satisfy the provider's plan-time validators. */

mock_data "aws_caller_identity" {
  defaults = {
    account_id = "111122223333"
    arn        = "arn:aws:iam::111122223333:root"
    user_id    = "111122223333"
  }
}

mock_data "aws_region" {
  defaults = {
    region = "us-west-2"
  }
}

mock_data "aws_iam_policy_document" {
  defaults = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

mock_resource "aws_cloudwatch_log_group" {
  defaults = {
    arn = "arn:aws:logs:us-west-2:111122223333:log-group:/aws/cloudtrail/global-terraform-state-cloudtrail"
  }
}

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::111122223333:role/global-terraform-state-iam-role-cloudtrail-logs"
    id  = "global-terraform-state-iam-role-cloudtrail-logs"
  }
}

mock_resource "aws_iam_policy" {
  defaults = {
    arn = "arn:aws:iam::111122223333:policy/global-terraform-state-iam-policy-monitoring-readonly"
  }
}

mock_resource "aws_sns_topic" {
  defaults = {
    arn = "arn:aws:sns:us-west-2:111122223333:global-terraform-state-sns-topic-alerts"
  }
}
