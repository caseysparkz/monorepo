# `ecr.caseysparkz.com`

These manifests read all `*.compose.yml` files in the root
[docker/](../../../../../docker/README.md)  directory and create an ECR
repository for each, before logging in to ECR and pushing the images.

## Usage

1. Add a `compose.yml` and `Dockerfile` to `docker/`. The Docker compose
    filename must be formatted as
   `${IMAGE_NAME}:${IMAGE_VERSION}.docker-compose.yml`
1. Run `terraform apply`.
