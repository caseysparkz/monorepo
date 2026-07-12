################################################################################
# Terraform Config and Providers
#

terraform {
  required_version = ">= 1.10.5, < 2.0.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.8.0, < 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0, < 7.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.19.1, < 6.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2, < 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.3, < 4.0.0"
    }
  }
}
