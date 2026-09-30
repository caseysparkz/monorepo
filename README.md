# `caseysparkz/monorepo`

This repository is a monorepo for everything I write. Its focus is predominantly
infrastructure-as-code, with a view to cloud security, and CI/CD.

## Software

### Required Software and Languages

* [Dagger](https://dagger.io/)
   * [Go](https://go.dev/doc/install) 1.26.4+
* [Docker](https://docs.docker.com/engine/install)
   * Docker Compose
* [Python](https://www.python.org/downloads/) 3.13+. Dependencies installed via
  `pip install .` include:
   * `ansible-core`
   * `boto3`
* [Terraform](https://developer.hashicorp.com/terraform/install)

### Recommended Software

* [gh](https://cli.github.com)
* [hadolint](https://hadolint.com)
* [infracost](https://www.infracost.io/docs/)
* [mdl](https://github.com/markdownlint/markdownlint)
* [mlc](https://github.com/becheran/mlc)
* [shellcheck](https://github.com/koalaman/shellcheck)
* [tfschema](https://github.com/minamijoyo/tfschema)
* [trivy](https://trivy.dev/docs/latest/getting-started/installation/)
* Python `[dev,test]` dependencies installed via `pip install .[all]` include:
   * `ansible-lint`
   * `ipython`
   * `moto`
   * `mypy`
   * `pip-audit`
   * `pytest-cov`
   * `pytest`
   * `ruff`
   * `yamllint`
   * `yq`

## Repository Structure

* [`ansible/`](./ansible/README.md). Ansible collections for hardening, tuning,
  and configuring Linux hosts.
* [`dagger/`](./dagger/README.md). Dagger CI modules (`dagger check`).
* [`docker/`](./docker/README.md). Dockerfiles and Compose files for base
  images pushed to ECR.
* `infra/manifests/`. Terraform root configurations, laid out by reverse domain
  (e.g. `com/caseysparkz/`).
* [`infra/modules/`](./infra/modules/README.md). Reusable Terraform modules.
* `.github/`. GitHub Actions workflows and supplementary configuration.

## Security

### Secrets Management

With the exception of AWS CLI credentials, all secrets should exist in AWS
Secrets Manager and be called by code.

### Prowler

I use Prowler internally for cloud security posture detection and management.

To exclude **known** false positives, add the tag 'Prowler=ignore' to a given
resource.

Run prowler scans against the AWS environment with:

```sh
prowler aws                                                                   \
    --region "${AWS_REGION}"                                                  \
    --profile "${AWS_PROFILE}"                                                \
    --mutelist-file .prowler/mutelist.yml                                     \
    --security-hub
```

## CI/CD

At this moment, CI/CD is split between GitHub Actions (old) and
Dagger (new). The `CI` GitHub Actions workflow already delegates most checks to
`dagger check`, filtered by which files changed in the pull request. GitHub is
becoming less-and-less reliable, and my CI/CD pipelines are really the only part
of my workflow with high vendor-lock-in.

I'll be fixing this over the coming weeks and months, as I move to a pure-Dagger
approach.
