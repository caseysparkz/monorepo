// A Dagger module for Python code
//
// This module runs any code pertaining to Python, eg: PyTest, MyPy.

package main

import (
	"context"
	"dagger/python/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"

// New - Default options for the Python Dagger module.
func New(
	// Version of Python to run
	// +optional
	// +default="3.13"
	pythonVersion string,
	// Path to run pytest/mypy/ruff/etc against.
	// +optional
	// +default="."
	pyPath string,
	// Project source directory
	// +optional
	// +ignore=["*","!**/*.py","!**/*.toml","!**/*.ini","!**/*.yaml","!**/*.yml","!**/*.cfg","!uv.lock","**/.venv"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Python {
	return &Python{
		Version: pythonVersion,
		Path:    pyPath,
		Source:  source,
	}
}

// Python - the Python Dagger module
type Python struct {
	Version string
	Path    string
	Source  *dagger.Directory
}

// Returns a container with uv installed and the repo as the pwd.
func (m *Python) container() *dagger.Container {
	return dag.Container().
		From(fmt.Sprintf("docker.io/library/python:%s-slim", m.Version)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithEnvVariable("PIP_ROOT_USER_ACTION", "ignore").
		WithExec([]string{"python", "-m", "pip", "install", "uv", "--quiet"})
}

// Returns a container with all uv dependency groups synced
func (m *Python) UvSync() *dagger.Container {
	return m.container().
		WithEnvVariable("UV_LINK_MODE", "copy").
		WithExec([]string{"uv", "sync", "--locked"})
}

// Test - Runs PyTest
// +check
func (m *Python) Test(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	return m.UvSync().WithExec(append([]string{"uv", "run", "pytest"}, file...)).Stdout(ctx)
}

// LintMypy - Runs MyPy
// +check
func (m *Python) LintMypy(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	return m.UvSync().
		WithExec(append([]string{"uv", "run", "mypy"}, file...)).Stdout(ctx)
}

// LintRuffCheck - Runs ruff-check
// +check
func (m *Python) LintRuffCheck(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	return m.UvSync().WithExec(append([]string{"uv", "run", "ruff", "check"}, file...)).Stdout(ctx)
}

// LintRuffFormat - Runs ruff-format --check
// +check
func (m *Python) LintRuffFormat(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	return m.UvSync().WithExec(append([]string{"uv", "run", "ruff", "format", "--check"}, file...)).Stdout(ctx)
}

// UvAudit - Runs uv-audit
// +check
func (m *Python) UvAudit(ctx context.Context) (string, error) {
	return m.UvSync().WithExec([]string{"uv", "run", "uv-audit"}).Stdout(ctx)
}

// UvLock - Checks if uv.lock is up-to-date
// +check
func (m *Python) UvLock(ctx context.Context) (string, error) {
	return m.UvSync().WithExec([]string{"uv", "lock", "--check"}).Stdout(ctx)
}
