// A generated module for Ansible functions

package main

import (
	"context"
	"dagger/ansible/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var ansibleDir = "./ansible/"

func New(
	// Path to the Ansible directory, relative to :arg source:.
	// +optional
	// +default="ansible"
	ansibleDir string,
	// AWS Access Key ID
	awsAccessKeyId *dagger.Secret,
	// AWS default region
	// +optional
	// +default="us-west-2"
	awsDefaultRegion string,
	// AWS Secret Access Key
	awsSecretAccessKey *dagger.Secret,
	// AWS Session Token
	// +optional
	awsSessionToken *dagger.Secret,
	// Pip package to install within :arg ansible-dir:
	// +optional
	// +default=".[test]"
	pipPackage string,
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
		AwsAccessKeyId:     awsAccessKeyId,
		AwsDefaultRegion:   awsDefaultRegion,
		AwsSecretAccessKey: awsSecretAccessKey,
		AwsSessionToken:    awsSessionToken,
		PipPackage:         pipPackage,
		PythonVersion:      pythonVersion,
		Source:             source,
	}
}

type Ansible struct {
	AnsibleDir         string
	AwsAccessKeyId     *dagger.Secret
	AwsDefaultRegion   string
	AwsSecretAccessKey *dagger.Secret
	AwsSessionToken    *dagger.Secret
	PipPackage         string
	PythonVersion      string
	Source             *dagger.Directory
}

// Returns a container with aws CLI installed, repo mounted, and ansible package installed.
func (m *Ansible) container() *dagger.Container {
	awsDirPath := "/usr/local/aws-cli"
	container := dag.Container().
		From(fmt.Sprintf("docker.io/library/python:%s-slim", m.PythonVersion)).
		WithMountedDirectory(mountPoint, m.Source).
		WithWorkdir(ansibleDir).
		WithExec([]string{"python", "-m", "ensurepip"}).
		WithExec([]string{"pip", "install", "--upgrade", "pip", "--quiet"})

	return dag.Python().Venv(container).
		// Make the AWS CLI available within context
		WithDirectory(awsDirPath, dag.Container().From("docker.io/amazon/aws-cli:latest").Directory(awsDirPath)).
		WithExec([]string{"ln", "-s", fmt.Sprintf("%s/v2/current/bin/aws", awsDirPath), "/usr/local/bin/aws"}).
		WithEnvVariable("AWS_DEFAULT_REGION", m.AwsDefaultRegion).
		WithSecretVariable("AWS_ACCESS_KEY_ID", m.AwsAccessKeyId).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", m.AwsSecretAccessKey).
		WithSecretVariable("AWS_SESSION_TOKEN", m.AwsSessionToken).
		// Set up Ansible
		WithWorkdir(m.AnsibleDir).
		WithExec([]string{"pip", "install", "--quiet", m.PipPackage})
}

// Runs ansible-lint against the ansible/ directory.
// +check
func (m *Ansible) Lint(ctx context.Context) (string, error) {
	stdout, err := m.container().
		WithMountedCache("/root/.cache/ansible-lint", dag.CacheVolume("docker.io/library/alpine:latest")).
		WithExec([]string{"ansible-lint"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	} else {
		return stdout, nil
	}
}

// Runs yamllint against the ansible/ directory.
// +check
func (m *Ansible) Yamllint(ctx context.Context) (string, error) {
	return dag.Yaml().Lint(ctx, dagger.YamlLintOpts{Path: ansibleDir})
}
