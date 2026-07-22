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

// Returns a container that echoes whatever string argument is provided
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
		WithExec(append([]string{"hadolint"}, file...)).
		Stdout(ctx)
}
