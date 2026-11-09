// A generated module for Yaml functions

package main

import (
	"context"
	"dagger/yaml/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"

// New - Default options for the Yaml Dagger module.
func New(
	// Version of Python to run
	// +optional
	// +default="3.13"
	pythonVersion string,
	// Project source directory
	// +optional
	// +defaultPath="/"
	// +ignore=["*","!**/pyproject.toml","!**/*.yaml","!**/*.yml","**/.venv"]
	source *dagger.Directory,
) *Yaml {
	return &Yaml{
		PyVersion: pythonVersion,
		Source:    source,
	}
}

// Yaml - the Yaml Dagger module.
type Yaml struct {
	PyVersion string
	Source    *dagger.Directory
}

// Lint - Returns the output of yamllint .
// +check
func (m *Yaml) Lint(
	ctx context.Context,
	// Path to pass to yamllint
	// +optional
	// +default="."
	path string,
) (string, error) {
	return dag.Container().
		From(fmt.Sprintf("docker.io/library/python:%s-slim", m.PyVersion)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithEnvVariable("PIP_ROOT_USER_ACTION", "ignore").
		WithEnvVariable("UV_LINK_MODE", "copy").
		WithExec([]string{"python", "-m", "pip", "install", "uv", "--quiet"}).
		WithExec([]string{"uv", "sync", "--all-extras", "--quiet"}).
		WithExec([]string{"uv", "run", "yamllint", path}).
		Stdout(ctx)
}
