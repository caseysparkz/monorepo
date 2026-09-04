/* Terraform and Providers */

// Terraform ===================================================================
terraform {
  required_version = ">= 1.10.5, < 2.0.0"

  backend "s3" {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/amazonaws/ecr.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.24.0"
    }
  }
}

// Providers ===================================================================
provider "aws" {
  region = "us-west-2"

  default_tags { tags = local.common_tags }
}

provider "cloudflare" {
  api_token = data.aws_secretsmanager_secret_version.cloudflare_token.secret_string
}

// Data ========================================================================
data "aws_secretsmanager_secret" "cloudflare_token" {
  arn = "arn:aws:secretsmanager:${local.aws_region}:${local.aws_account_id}:secret:cloudflare/api_token"
}

data "aws_secretsmanager_secret_version" "cloudflare_token" {
  secret_id = data.aws_secretsmanager_secret.cloudflare_token.id
}
