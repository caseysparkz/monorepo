/* Terraform and Providers */

// Terraform ===================================================================
terraform {
  required_version = ">= 1.13.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.64.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }

  backend "s3" {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/amazonaws/bedrock.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

// Providers ===================================================================
provider "aws" {
  region = var.aws_region

  default_tags { tags = local.common_tags }
}
