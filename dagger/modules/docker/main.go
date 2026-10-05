// A generated module for Docker functions

package main

import (
	"context"
	"dagger/docker/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"

// New - Default options for the Docker Dagger module.
func New(
	// Project source directory
	// +optional
	// +ignore=["*","!docker/","!.hadolint.yaml"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Docker {
	return &Docker{
		Source: source,
	}
}

// Docker - The dagger Docker module
type Docker struct {
	Source *dagger.Directory
}

// Hadolint - Runs hadolint (Dockerfile linter) against files.
func (m *Docker) Hadolint(
	ctx context.Context,
	// Files to lint.
	file []string,
	// Version of Hadolint to use.
	// +optional
	// +default="2.14.0"
	hadolintVersion string,
) (string, error) {

	return dag.Container().
		From(fmt.Sprintf("ghcr.io/hadolint/hadolint:v%s", hadolintVersion)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec(append([]string{"hadolint", "--no-color"}, file...)).
		Stdout(ctx)
}

// ComposeConfig - Checks the validity of a docker compose file.
func (m *Docker) ComposeConfig(
	ctx context.Context,
	// File to lint.
	file string,
	// Version of docker-compose to use.
	// +optional
	// +default="latest"
	composeVersion string,
) (string, error) {
	return dag.Container().
		From(fmt.Sprintf("docker.io/library/docker:%s", composeVersion)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec([]string{"docker", "compose", "--file", file, "config"}).
		Stdout(ctx)
}
