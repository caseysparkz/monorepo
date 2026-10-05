// A generated module for Yaml functions

package main

import (
	"context"
	"dagger/yaml/internal/dagger"
)

// New - Default options for the Yaml Dagger module.
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

// Yaml - the Yaml Dagger module.
type Yaml struct {
	Source *dagger.Directory
}

func (m *Yaml) container() *dagger.Container {
	return dag.Python().PipInstall()
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
	return m.container().WithExec([]string{"yamllint", path}).Stdout(ctx)
}
