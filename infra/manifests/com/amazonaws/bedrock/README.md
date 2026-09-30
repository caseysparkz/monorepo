# AWS Bedrock

This directory contains manifests for deploying Anthropic frontier models in AWS
Bedrock, using the [`bedrock`](../../../../modules/bedrock/) module.

The manifests also create:

* An IAM policy allowing use of the inference profile.
* Model invocation logging to CloudWatch and to S3.

## Variables

* `enabled`: Whether to create the inference profile. Default `false`.
* `aws_region`: AWS region to deploy resources to. Default `us-west-2`.
* `aws_bedrock_foundation_model_id`: Foundation model to deploy. Default
  `anthropic.claude-opus-5`.
* `aws_bedrock_cross_region`: Cross-region inference profile (`global` or
  `us`). Default `global`.

## Deploying the Manifests

These manifests are already deployed, however the inference profile is spun up
on demand by passing `-var enabled=true` to `terraform apply`.

```sh
terraform apply -var enabled=true
```

To remove the inference profile after use, run:

```sh
terraform apply
```

For more information on AWS Bedrock pricing, click
[here](https://aws.amazon.com/bedrock/pricing/).

## Connecting Claude Code to Bedrock

```sh
export CLAUDE_CODE_USE_BEDROCK="1"
export AWS_REGION="us-west-2"

claude
```
