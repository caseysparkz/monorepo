// A generated module for Shell functions

package main

import (
	"context"
	"dagger/shell/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"

// New - Default options for the Shell Dagger module.
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

// Shell - the Shell Dagger module.
type Shell struct {
	Version string
	Source  *dagger.Directory
}

// Lint - Runs shellcheck against a given path (or paths).
func (m *Shell) Lint(
	ctx context.Context,
	// Files to lint (relative to :arg source:).
	file []string,
) (string, error) {
	return dag.Container().
		From(fmt.Sprintf("770088062852.dkr.ecr.us-west-2.amazonaws.com/shellcheck:%s", m.Version)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec(append([]string{"shellcheck"}, file...)).
		Stdout(ctx)
}
