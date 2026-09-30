# Docker

This directory contains Dockerfiles and Docker Compose files for my base
images. The [ECR manifests](../infra/manifests/com/amazonaws/ecr/README.md)
build each image and push it to ECR.

## Adding an Image

Each image needs two files:

* `${IMAGE_NAME}.Dockerfile`
* `${IMAGE_NAME}:${IMAGE_VERSION}.compose.yml`, whose `build.dockerfile` points
  at the Dockerfile above, and whose `image` is the ECR repository URL.

Build an image locally with:

```sh
docker compose -f "${IMAGE_NAME}:${IMAGE_VERSION}.compose.yml" build
```
