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
	// +ignore=["*","!ansible/**","!**/*.toml","!**/*.ini","!**/*.py","!**/*.yml","!**/*.yaml"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Ansible {
	return &Ansible{
		AnsibleDir:         fmt.Sprintf("%s/%s", mountPoint, ansibleDir),
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
	AnsibleDir         string
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

	return dag.Python().
		UvSync().
		// Make the AWS CLI available within context
		WithDirectory(awsDirPath, dag.Container().From("docker.io/amazon/aws-cli:latest").Directory(awsDirPath)).
		WithExec([]string{"ln", "-s", fmt.Sprintf("%s/v2/current/bin/aws", awsDirPath), "/usr/local/bin/aws"}).
		WithEnvVariable("AWS_DEFAULT_REGION", m.AwsDefaultRegion).
		WithSecretVariable("AWS_ACCESS_KEY_ID", m.AwsAccessKeyID).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", m.AwsSecretAccessKey).
		WithSecretVariable("AWS_SESSION_TOKEN", m.AwsSessionToken).
		// Set up Ansible
		WithWorkdir(m.AnsibleDir)
}

// Lint - Runs ansible-lint against the ansible/ directory.
// +check
func (m *Ansible) Lint(ctx context.Context) (string, error) {
	stdout, err := m.container().
		WithEnvVariable("UV_LINK_MODE", "copy").
		WithMountedCache("/root/.cache/ansible-lint", dag.CacheVolume("docker.io/library/alpine:latest")).
		WithExec([]string{"uv", "run", "ansible-lint"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return stdout, nil
}
