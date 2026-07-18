# Terraform Dagger Module

This dagger module provides the following functions/checks:

**apply**. Returns the output of `terraform plan`.
**fmt-recursive**. (Check) Returns the output of `terraform -chdir={} fmt -recursive -check`.
**plan**. Returns the output of `terraform plan`.
**validate**. Returns the output of `terraform plan`.

The module requires the following arguments:

`--aws-default-region`: Defaults to `${AWS_DEFAULT_REGION}`.
`--aws-access-key-id`: Defaults to `${AWS_ACCESS_KEY_ID}`.
`--aws-secret-access-key`: Defaults to `${AWS_SECRET_ACCESS_KEY}`.
`--aws-session-token`: Defaults to `${AWS_SESSION_TOKEN}`.
`--tf-version`: Default `1.15.8`.
`--sourc`: Defaults to the repository root directory.
