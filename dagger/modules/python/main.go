// A Dagger module for Python functions
//
// This module runs any code pertaining to Python, eg: PyTest, MyPy.

package main

import (
	"context"
	"dagger/python/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var image = "docker.io/library/python"

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
	// +ignore=["*cache*",".coverage",".env",".git*",".terraform",".venv","build","dist","node_modules","*.log"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Python {
	return &Python{
		Image:   fmt.Sprintf("%s:%s-slim", image, pythonVersion),
		VenvDir: fmt.Sprintf("%s/.venv", mountPoint),
		Path:    pyPath,
		Source:  source,
		Pkg:     pkg,
	}
}

type Python struct {
	Image   string
	VenvDir string
	Path    string
	Source  *dagger.Directory
	Pkg     string
}

// Returns a container with pip installed and the repo as the pwd.
func (m *Python) container() *dagger.Container {
	return dag.Container().
		From(m.Image).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec([]string{"python", "-m", "ensurepip"})
}

// Returns a container with an initialized and empty virtual environment.
func (m *Python) Venv() *dagger.Container {
	return m.container().
		WithMountedCache(m.VenvDir, dag.CacheVolume(m.Image)).
		WithExec([]string{"python", "-m", "venv", m.VenvDir}).
		WithEnvVariable("VIRTUAL_ENV", m.VenvDir).
		WithEnvVariable("PATH", "${VIRTUAL_ENV}/bin:${PATH}", dagger.ContainerWithEnvVariableOpts{Expand: true})
}

// Returns a container with an installed package.
func (m *Python) PipInstall() *dagger.Container {
	return m.Venv().WithExec([]string{"pip", "install", "--quiet", "--root-user-action=ignore", m.Pkg})
}

// Runs PyTest
// +check
func (m *Python) Pytest(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	stdout, err := m.PipInstall().WithExec(append([]string{"pytest"}, file...)).Stdout(ctx)

	if err != nil {
		return "", fmt.Errorf("Error: %s", err)
	} else {
		return stdout, nil
	}
}

// Runs MyPy
// +check
func (m *Python) Mypy(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	stdout, err := m.PipInstall().WithExec(append([]string{"mypy"}, file...)).Stdout(ctx)

	if err != nil {
		return "", fmt.Errorf("Error: %s", err)
	} else {
		return stdout, nil
	}
}

// Runs ruff-check
// +check
func (m *Python) RuffCheck(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	stdout, err := m.PipInstall().WithExec(append([]string{"ruff", "check"}, file...)).Stdout(ctx)

	if err != nil {
		return "", fmt.Errorf("Error: %s")
	} else {
		return stdout, nil
	}
}

// Runs ruff-format --check
// +check
func (m *Python) RuffFormat(
	ctx context.Context,
	// Files/directories to lint.
	// +optional
	// +default=["."]
	file []string,
) (string, error) {
	stdout, err := m.PipInstall().WithExec(append([]string{"ruff", "format", "--check"}, file...)).Stdout(ctx)

	if err != nil {
		return "", fmt.Errorf("Error: %w", err)
	} else {
		return stdout, nil
	}
}

// Runs pip-audit
// +check
func (m *Python) PipAudit(ctx context.Context) (string, error) {
	stdout, err := m.PipInstall().WithExec([]string{"pip-audit", mountPoint}).Stdout(ctx)

	if err != nil {
		return "", fmt.Errorf("Error: %w", err)
	} else {
		return stdout, nil
	}
}

// Checks if pylock.toml is up-to-date
// +check
func (m *Python) Pylock(ctx context.Context) (string, error) {
	lockfile := fmt.Sprintf("%s/pylock.toml", mountPoint)
	prehash, hashError := m.container().File(lockfile).Digest(ctx)
	posthash, _ := m.PipInstall().WithExec([]string{"pip", "lock", m.Pkg}).File(lockfile).Digest(ctx)

	if hashError != nil {
		return "", fmt.Errorf("Could not hash pylock.toml: %s", hashError)
	} else if prehash != posthash {
		return "", fmt.Errorf("Hashes do not match. pylock.toml has not been updated.")
	} else {
		return "pylock.toml is up to date", nil
	}
}
