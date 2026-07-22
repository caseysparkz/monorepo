// A generated module for Yaml functions

package main

import (
	"context"
	"dagger/yaml/internal/dagger"
)

var mountPoint = "/mnt"

func New(
	// Project source directory
	// +optional
	// +ignore=["*cache*",".coverage",".env",".git*",".terraform",".venv","build","dist","node_modules","*.log"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Yaml {
	return &Yaml{
		Source: source,
	}
}

type Yaml struct {
	Source *dagger.Directory
}

func (m *Yaml) container() *dagger.Container {
	return dag.Python().PipInstall()
}

// Returns the output of yamllint .
// +check
func (m *Yaml) Lint(
	ctx context.Context,
	// Path to pass to yamllint
	// +optional
	// +default="."
	path string,
) (string, error) {
	stdout, stderr := m.container().WithExec([]string{"yamllint", path}).Stdout(ctx)

	if stderr != nil {
		return "", stderr
	} else {
		return stdout, nil
	}
}
