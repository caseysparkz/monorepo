################################################################################
# Terraform and Providers
#

# Terraform ====================================================================
terraform {
  required_version = ">= 1.10.5, < 2.0.0"

  backend "s3" {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/amazonaws/iam/github_actions.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52.0"
    }
  }
}

# Providers ====================================================================
provider "aws" {
  region = var.aws_region

  default_tags { tags = local.common_tags }
}

# Secrets ======================================================================
data "aws_caller_identity" "this" {}

data "aws_secretsmanager_secret" "github_token" {
  /*
  This is a non-expiring, fine-grainedd GitHub token with the following scopes:

  Repositories:

  * Administration: Write
  * Contents: Write
  * Metadata: Read
  */
  arn = "arn:aws:secretsmanager:${var.aws_region}:${local.aws_account_id}:secret:github/api_token"
}

ephemeral "aws_secretsmanager_secret_version" "github_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}
