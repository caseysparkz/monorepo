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
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 4.4.0, < 5.0.0"
    }
  }
}

# Providers ====================================================================
provider "docker" {
  host = var.docker_socket

  registry_auth {
    address  = local.ecr_authorization_token.proxy_endpoint
    username = local.ecr_authorization_token.user_name
    password = local.ecr_authorization_token.password
  }
}
