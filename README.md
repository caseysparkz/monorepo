# `caseysparkz/infrastructure`

This repository is a monorepo for everything I write.

## Software

### Required Software

* Terraform
* Docker+Docker Compose
* Python 3.14+. Dependencies installed via `pip install .` include:
   * `ansible`
   * `boto3`

### Recommended Software

* `gh`
* `hadolint`
* `infracost`
* `mdl`
* `mlc`
* `shellcheck`
* `tfschema`
* `trivy`
* `yamllint`
* Python `[dev,test]` dependencies installed via `pip install .[all]` include:
   * `ansible-lint`
   * `ipython`
   * `mypy`
   * `pip-audit`
   * `pytest`
   * `pytest-cov`
   * `ruff'

## Filesystem Hierarchy

* Each domain contains its own directory in the top-level repository.
* Each component (Docker images, k8s configurations, Ansible playbooks,
   Terraform configurations) has its own subdirectory under its relevant domain.

## Secrets Management

With the exception of your AWS CLI credentials, all secrets should exist in AWS
Secrets Manager and be called by code.
