/* Input validation for the principal ARN variables. */

mock_provider "aws" {
  override_during = plan
  source          = "./tests/mocks"
}

run "default_variables_are_valid" {
  command = plan
}

run "rejects_empty_admin_principals" {
  command = plan

  variables {
    admin_principal_arns = []
  }

  expect_failures = [var.admin_principal_arns]
}

run "rejects_wildcard_admin_principal" {
  command = plan

  variables {
    admin_principal_arns = ["arn:aws:iam::111122223333:role/*"]
  }

  expect_failures = [var.admin_principal_arns]
}

run "rejects_non_iam_admin_principal" {
  command = plan

  variables {
    admin_principal_arns = ["arn:aws:s3:::com.caseysparkz.tfstate"]
  }

  expect_failures = [var.admin_principal_arns]
}

run "rejects_empty_writer_principals" {
  command = plan

  variables {
    writer_principal_arns = []
  }

  expect_failures = [var.writer_principal_arns]
}

run "rejects_wildcard_writer_principal" {
  command = plan

  variables {
    writer_principal_arns = ["arn:aws:iam::111122223333:role/gha-?"]
  }

  expect_failures = [var.writer_principal_arns]
}

run "rejects_short_account_id_writer_principal" {
  command = plan

  variables {
    writer_principal_arns = ["arn:aws:iam::1234:role/writer"]
  }

  expect_failures = [var.writer_principal_arns]
}

run "allows_empty_reader_principals" {
  command = plan

  variables {
    reader_principal_arns = []
  }
}

run "rejects_wildcard_reader_principal" {
  command = plan

  variables {
    reader_principal_arns = ["*"]
  }

  expect_failures = [var.reader_principal_arns]
}

run "accepts_govcloud_and_sts_principals" {
  command = plan

  variables {
    admin_principal_arns  = ["arn:aws-us-gov:iam::111122223333:role/admin"]
    writer_principal_arns = ["arn:aws:sts::111122223333:assumed-role/writer/session"]
    reader_principal_arns = ["arn:aws:iam::111122223333:user/reader"]
  }
}
