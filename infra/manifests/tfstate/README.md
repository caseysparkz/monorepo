# Terraform State

This directory contains the configuration for the AWS S3 bucket for all
Terraform states within my domain.

## Requirements

### Software

* [AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Usage

The bucket already exists, and its state is stored in itself (key
`tfstate.tfstate`). Apply changes as normal with `terraform apply`.

To bootstrap the bucket from scratch:

1. Ensure your AWS credentials are present and correct in your shell.
1. Comment out the `backend` configuration block in `providers.tf`.
1. Apply the configuration (`terraform apply`).
1. Uncomment the `backend` configuration block in `providers.tf`.
1. Migrate the local state to the bucket (`terraform init -migrate-state`).
