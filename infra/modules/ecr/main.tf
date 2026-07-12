################################################################################
# Main
#

locals {
  ecr_admin_email         = "ecr_admin@${var.root_domain}"
  ecr_authorization_token = data.aws_ecr_authorization_token.token
  ecr_registry_url        = replace(local.ecr_authorization_token.proxy_endpoint, "https://", "")
  ecr_repositories        = [for f in local.dockerfiles : replace(f, ".Dockerfile", "")]
  docker_compose_files    = fileset("${var.docker_compose_dir}/", "*.compose.yml")
  dockerfiles             = fileset("${var.docker_compose_dir}/", "*.Dockerfile")
}

# Data =========================================================================
data "aws_ecr_authorization_token" "token" {}

# Resources ====================================================================
resource "aws_ecr_repository" "this" {
  for_each             = toset(local.ecr_repositories)
  name                 = each.key
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.aws_kms_key_arn
  }
}

resource "null_resource" "docker_login" { # Log in to ECR
  depends_on = [aws_ecr_repository.this]

  provisioner "local-exec" {
    command = "aws ecr get-login-password | docker login ${local.ecr_registry_url} -u AWS --password-stdin"
  }
}

resource "null_resource" "docker_compose_build" { # Build images
  depends_on = [null_resource.docker_login]
  for_each   = local.docker_compose_files
  triggers   = { filehash = filesha1("${var.docker_compose_dir}/${each.key}") } # If dockerfile has changed.

  provisioner "local-exec" {
    working_dir = var.docker_compose_dir
    command     = "docker compose -f ${each.key} build"
    quiet       = true
  }
}

resource "docker_registry_image" "this" { # Push images to ECR
  depends_on = [null_resource.docker_compose_build]
  for_each   = toset([for file in local.docker_compose_files : replace(file, ".compose.yml", "")])
  name       = "${local.ecr_registry_url}/${each.key}"
}

# Outputs ======================================================================
output "ecr_registry_url" {
  description = "URL of the deployed ECR registry."
  value       = replace(data.aws_ecr_authorization_token.token.proxy_endpoint, "https://", "")
  sensitive   = false
}

output "ecr_registry_repository_urls" {
  description = "List of URLs for deployed ECR registries."
  value       = [for v in aws_ecr_repository.this : v.repository_url]
  sensitive   = false
}
