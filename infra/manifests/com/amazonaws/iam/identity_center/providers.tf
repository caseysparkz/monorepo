// Terraform ===================================================================
terraform {
  required_version = ">= 1.13.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66.0"
    }
  }

  backend "s3" {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/amazonaws/iam/ssoadmin.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

// Providers ===================================================================
provider "aws" {
  region = "us-west-2"

  default_tags { tags = local.common_tags }
}
