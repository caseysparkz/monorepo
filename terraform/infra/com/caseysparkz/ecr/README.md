# `ecr.caseysparkz.com`

These manifests read all docker-compose files in the
[docker_compose](./docker_compose) directory and create an ECR repository for
each, before logging in to ECR and pushing the images.

## Usage

1. Add a docker-compose file to `./docker_compose`. The filename must be
   formatted as `${IMAGE_NAME}:${IMAGE_VERSION}.docker-compose.yml`
1. Run `terraform apply`.
