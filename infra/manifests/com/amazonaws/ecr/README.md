# `ecr.caseysparkz.com`

These manifests read all `*.compose.yml` files in the root
[docker/](../../../../../docker/README.md) directory and create an ECR
repository for each, before logging in to ECR and pushing the images.

## Usage

1. Add a `Dockerfile` and `compose.yml` to `docker/`. The file names must be
   formatted as `${IMAGE_NAME}.Dockerfile` and
   `${IMAGE_NAME}:${IMAGE_VERSION}.compose.yml`, respectively.
1. Run `terraform apply`.
