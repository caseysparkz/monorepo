# `infra/modules`

Where I keep my Terraform modules!

* `aws_resourcegroup_by_tagset`. An AWS resource group matching a set of tags.
* `bedrock`. Bedrock model agreement and application inference profile.
* `ecr`. ECR repositories, built and pushed from the `docker/` Compose files.
* `hugo_static_site`. A Hugo static site on S3, with a Lambda contact form.
* `proton_domain`. Proton mail DNS records for a domain.
* [`s3_artifacts`](./s3_artifacts/README.md). An S3 bucket for Lambda
  artifacts.
