// A generated module for Shell functions

package main

import (
	"context"
	"dagger/shell/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var image = "docker.io/koalaman/shellcheck"

func New(
	// Version of shellcheck to run
	// +optional
	// +default="0.10.0"
	version string,
	// Project source directory
	// +optional
	// +ignore=["*cache*",".coverage",".env",".git",".terraform",".venv","build","dist","node_modules","*.log"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Shell {
	return &Shell{
		Version: version,
		Source:  source,
	}
}

type Shell struct {
	Version string
	Source  *dagger.Directory
}

// Returns a container that echoes whatever string argument is provided
func (m *Shell) Lint(
	ctx context.Context,
	// File to lint (relative to :arg source:).
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	return dag.Container().
		From(fmt.Sprintf("%s:v%s", image, m.Version)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec(append([]string{"shellcheck"}, files...)).
		Stdout(ctx)
}
