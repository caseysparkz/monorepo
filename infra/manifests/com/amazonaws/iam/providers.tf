/* Terraform and Providers */

// Terraform ===================================================================
terraform {
  required_version = "~> 1.15.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62.0"
    }
  }

  backend "s3" {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/amazonaws/iam.tfstate"
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
