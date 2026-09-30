# `caseysparkz.com`

This directory, and its subdirectories, contain the complete Terraform
configurations for my domain, ([caseysparkz.com](https://www.caseysparkz.com)).

Root domain configurations (root DNS, Proton mail, the shared KMS key, and the
logging bucket) are described in the Terraform files in this directory, while
subdomain/service configurations can be found in their respective
subdirectories.

## Software Requirements and Recommendations

### Required Software

The following utilities are **required** to deploy these manifests in their
entirety:

* [AWS
   CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Docker Compose](https://docs.docker.com/compose/install)
* [Docker](https://docs.docker.com/engine/install)
* [Hugo](https://gohugo.io/installation/)
* [pnpm](https://pnpm.io/installation)
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Recommended Software

The following utilities are **recommended**:

* [Infracost](https://www.infracost.io/docs/)
* [Ruff](https://docs.astral.sh/ruff/installation/)

## Access Requirements

### AWS

AWS credentials with access to the `com.caseysparkz.tfstate` state bucket and
the resources being deployed.

### Cloudflare

A Cloudflare API token, stored in AWS Secrets Manager as
`cloudflare/api_token`. The manifests read it at plan/apply time.
