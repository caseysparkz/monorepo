# com.caseysparkz.tfstate

This directory contains the configuration for the AWS S3 bucket for all
Terraform states within my domain.

## Requirements

### Softwares

* [AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Usage

1. Ensure that the above environment variables are present and correct in your
   shell.
1. Apply the configuration (`terraform apply`).
1. Uncomment the `backend` configuration block in `providers.tf`.
1. Reapply the configuration.
