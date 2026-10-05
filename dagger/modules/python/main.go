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
	// Package to install.
	// +optional
	// +default=".[all]"
	pkg string,
	// Project source directory
	// +optional
	// +ignore=["*","!**/*.py","!**/*.toml","!**/*.ini","!**/*.yaml","!**/*.yml","**/.venv"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Python {
	return &Python{
		Version: pythonVersion,
		VenvDir: fmt.Sprintf("%s/.venv", mountPoint),
		Path:    pyPath,
		Source:  source,
		Pkg:     pkg,
	}
}

// Python - the Python Dagger module
type Python struct {
	Version string
	VenvDir string
	Path    string
	Source  *dagger.Directory
	Pkg     string
}

// Returns a container with pip installed and the repo as the pwd.
func (m *Python) container() *dagger.Container {
	return dag.Container().
		From(fmt.Sprintf("docker.io/library/python:%s-slim", m.Version)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithEnvVariable("PIP_ROOT_USER_ACTION", "ignore").
		WithExec([]string{"python", "-m", "ensurepip"}).
		WithExec([]string{"pip", "install", "--upgrade", "pip", "--quiet"})
}

// Venv - Returns a container with an initialized and empty virtual environment.
func (m *Python) Venv(container *dagger.Container) *dagger.Container {
	return container.
		WithMountedCache(
			m.VenvDir,
			dag.CacheVolume(fmt.Sprintf("docker.io/library/python:%s-slim", m.Version)),
		).
		WithExec([]string{"python", "-m", "venv", m.VenvDir}).
		WithEnvVariable("VIRTUAL_ENV", m.VenvDir).
		WithEnvVariable("PATH", "${VIRTUAL_ENV}/bin:${PATH}", dagger.ContainerWithEnvVariableOpts{Expand: true})
}

// PipInstall - Returns a container with an installed package.
func (m *Python) PipInstall() *dagger.Container {
	return m.Venv(m.container()).WithExec([]string{"pip", "install", "--quiet", m.Pkg})
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
	return m.PipInstall().WithExec(append([]string{"pytest"}, file...)).Stdout(ctx)
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
	return m.PipInstall().WithExec(append([]string{"mypy"}, file...)).Stdout(ctx)
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
	return m.PipInstall().WithExec(append([]string{"ruff", "check"}, file...)).Stdout(ctx)
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
	return m.PipInstall().WithExec(append([]string{"ruff", "format", "--check"}, file...)).Stdout(ctx)
}

// PipAudit - Runs pip-audit
// +check
func (m *Python) PipAudit(ctx context.Context) (string, error) {
	return m.PipInstall().WithExec([]string{"pip-audit", mountPoint}).Stdout(ctx)
}

// Pylock - Checks if pylock.toml is up-to-date
// +check
func (m *Python) Pylock(ctx context.Context) (string, error) {
	lockfile := fmt.Sprintf("%s/pylock.toml", mountPoint)
	prehash, hashError := m.container().File(lockfile).Digest(ctx)
	posthash, _ := m.PipInstall().
		WithExec([]string{"pip", "lock", m.Pkg}).
		File(lockfile).
		Digest(ctx)

	if hashError != nil {
		return "", fmt.Errorf("could not hash pylock.toml: %s", hashError)
	} else if prehash != posthash {
		return "", fmt.Errorf("hashes do not match: pylock.toml has not been updated")
	} else {
		return "pylock.toml is up to date", nil
	}
}
