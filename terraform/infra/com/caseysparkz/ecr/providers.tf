################################################################################
# Terraform and Providers
#

# Terraform ====================================================================
terraform {
  required_version = ">= 1.10.5, < 2.0.0"

  backend "s3" {
    bucket       = "com.caseysparkz.tfstate"
    key          = "com/caseysparkz/ecr.tfstate"
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
  region = "us-west-2"

  default_tags { tags = local.common_tags }
}
