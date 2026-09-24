# AWS Bedrock

This directory contains manifests for deploying Anthropic frontier models in AWS
Bedrock.

## Usage

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

claude
```
