# Terraform Dagger Module

This dagger module provides the following functions and checks:

* **apply**. Plans, then runs `terraform apply -auto-approve` on the planfile.
* **fmt**. (Check) Runs `terraform -chdir={} fmt -check -recursive`.
* **plan**. Returns the output of `terraform show` on a fresh planfile.
* **validate**. Returns the output of `terraform -chdir={} validate`.

All functions take a `--chdir` argument (default `.` for `fmt`; required
otherwise). `apply` and `plan` also accept an optional `--var-file`, relative
to `--chdir`.

The module accepts the following arguments:

* `--aws-default-region`: Required. Defaults to `${AWS_DEFAULT_REGION}` (via
  `.env`).
* `--aws-access-key-id`: Required. Defaults to `${AWS_ACCESS_KEY_ID}` (via
  `.env`).
* `--aws-secret-access-key`: Required. Defaults to `${AWS_SECRET_ACCESS_KEY}`
  (via `.env`).
* `--aws-session-token`: Optional. Defaults to `${AWS_SESSION_TOKEN}` (via
  `.env`).
* `--terraform-version`: Default `1.15.8`.
* `--source`: Defaults to the repository root directory.
