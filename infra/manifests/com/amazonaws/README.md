# 'amazonaws.com'

Contains global configs for my AWS account and organization.

Mostly organization policies (EC2, S3). Subdirectories:

* [`bedrock/`](./bedrock/README.md). AWS Bedrock model access, inference
  profiles, and invocation logging.
* [`ecr/`](./ecr/README.md). ECR repositories for the images in `docker/`.
* `iam/`. Account permissions boundary, IAM Identity Center permission sets,
  and OIDC providers (GitHub Actions).

**NB:** Must be run from the root account, or an account with delegate access.
