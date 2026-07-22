// A generated module for Docker functions

package main

import (
	"context"
	"dagger/docker/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"

func New(
	// Project source directory
	// +optional
	// +ignore=["*cache*",".coverage",".env",".git",".terraform",".venv","build","dist","node_modules","*.log"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Docker {
	return &Docker{
		Source: source,
	}
}

type Docker struct {
	Source *dagger.Directory
}

// Runs hadolint (Dockerfile linter) against files
func (m *Docker) Hadolint(
	ctx context.Context,
	// Files to lint.
	file []string,
	// Version of Hadolint to use.
	// +optional
	// +default="2.14.0"
	hadolintVersion string,
) (string, error) {
	image := fmt.Sprintf("%s:v%s", "ghcr.io/hadolint/hadolint", hadolintVersion)

	return dag.Container().
		From(image).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec(append([]string{"hadolint", "--no-color"}, file...)).
		Stdout(ctx)
}

// Returns a container that echoes whatever string argument is provided
func (m *Docker) ComposeConfig(
	ctx context.Context,
	// File to lint.
	file string,
	// Version of docker-compose to use.
	// +optional
	// +default="latest"
	composeVersion string,
) (string, error) {
	image := fmt.Sprintf("%s:%s", "docker.io/docker/compose", composeVersion)

	return dag.Container().
		From(image).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec([]string{"docker", "compose", file}).
		Stdout(ctx)
}
