// A generated module for Ansible functions

package main

import (
	"context"
	"dagger/ansible/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var ansibleDir = "./ansible/"

// New - Default options for the Ansible Dagger module.
func New(
	// Path to the Ansible directory, relative to :arg source:.
	// +optional
	// +default="ansible"
	ansibleDir string,
	// AWS Access Key ID
	awsAccessKeyID *dagger.Secret,
	// AWS default region
	// +optional
	// +default="us-west-2"
	awsDefaultRegion string,
	// AWS Secret Access Key
	awsSecretAccessKey *dagger.Secret,
	// AWS Session Token
	// +optional
	awsSessionToken *dagger.Secret,
	// Version of Python to run
	// +optional
	// +default="3.13"
	pythonVersion string,
	// Project source directory
	// +optional
	// +defaultPath="/ansible"
	// +ignore=["*","!**/*.yml","!**/*.yaml","!**/*.cfg","!**/*.toml","!**/*.md"]
	source *dagger.Directory,
) *Ansible {
	return &Ansible{
		AwsAccessKeyID:     awsAccessKeyID,
		AwsDefaultRegion:   awsDefaultRegion,
		AwsSecretAccessKey: awsSecretAccessKey,
		AwsSessionToken:    awsSessionToken,
		PythonVersion:      pythonVersion,
		Source:             source,
	}
}

// Ansible - Dagger Ansible module.
type Ansible struct {
	AwsAccessKeyID     *dagger.Secret
	AwsDefaultRegion   string
	AwsSecretAccessKey *dagger.Secret
	AwsSessionToken    *dagger.Secret
	PythonVersion      string
	Source             *dagger.Directory
}

// Returns a container with aws CLI installed, repo mounted, and ansible package installed.
func (m *Ansible) container() *dagger.Container {
	awsDirPath := "/usr/local/aws-cli"

	return dag.Container().
		From(fmt.Sprintf("docker.io/library/python:%s-slim", m.PythonVersion)).
		WithDirectory(awsDirPath, dag.Container().From("docker.io/amazon/aws-cli:latest").Directory(awsDirPath)).
		WithExec([]string{"ln", "-s", fmt.Sprintf("%s/v2/current/bin/aws", awsDirPath), "/usr/local/bin/aws"}).
		WithEnvVariable("AWS_DEFAULT_REGION", m.AwsDefaultRegion).
		WithSecretVariable("AWS_ACCESS_KEY_ID", m.AwsAccessKeyID).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", m.AwsSecretAccessKey).
		WithSecretVariable("AWS_SESSION_TOKEN", m.AwsSessionToken).
		WithEnvVariable("UV_LINK_MODE", "copy").
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(mountPoint).
		WithExec([]string{"python", "-m", "pip", "install", "uv", "--quiet"}).
		WithExec([]string{"uv", "sync", "--all-extras", "--quiet"})
}

// Lint - Runs ansible-lint against the ansible/ directory.
// +check
func (m *Ansible) Lint(ctx context.Context) (string, error) {
	stdout, err := m.container().
		WithMountedCache("/root/.cache/ansible-lint", dag.CacheVolume("docker.io/library/alpine:latest")).
		WithExec([]string{"uv", "run", "ansible-lint"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return stdout, nil
}
