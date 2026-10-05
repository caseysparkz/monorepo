// A Dagger module for Go functions code.
//
// This module runs any code pertaining to Go (such as golangci-lint).

package main

import (
	"context"
	"dagger/go/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var golintVersion = "v0.0.0-20241112194109-818c5a804067"

// New - Default options for the Go Dagger module.
func New(
	// Version of Go to run
	// +optional
	// +default="1.27.1"
	goVersion string,
	// Project source directory
	// +optional
	// +ignore=["*","!**/*.go","!*/go.sum","!*/go.mod","**/internal/**"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Go {
	return &Go{
		Version: goVersion,
		Source:  source,
	}
}

// Go - the Go Dagger module.
type Go struct {
	Version string
	Source  *dagger.Directory
}

// Returns a container with go installed and the repo as the pwd
func (m *Go) container() *dagger.Container {
	return dag.Container().From(fmt.Sprintf("docker.io/library/golang:%s-trixie", m.Version)).
		WithExec([]string{"go", "install", fmt.Sprintf("golang.org/x/lint/golint@%s", golintVersion)}).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint)
}

// Lint - Runs golint recursively, or against a given path
// +check
func (m *Go) Lint(
	ctx context.Context,
	// Path to run golangci-lint against
	// +optional
	// +default="./..."
	path string,
) (string, error) {
	return m.container().WithExec([]string{"golint", path}).Stdout(ctx)
}
