################################################################################
# Terraform and Providers
#

# Terraform ====================================================================
terraform {
  required_version = ">= 1.10.5, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0, < 7.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.0, < 4.0.0"
    }
  }
}
