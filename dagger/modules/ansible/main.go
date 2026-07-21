// A generated module for Ansible functions

package main

import (
	"context"
	"dagger/ansible/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"

func New(
	// AWS default region
	// +optional
	// +default="us-west-2"
	awsDefaultRegion string,
	// AWS Access Key ID
	awsAccessKeyId *dagger.Secret,
	// AWS Secret Access Key
	awsSecretAccessKey *dagger.Secret,
	// AWS Session Token
	// +optional
	awsSessionToken *dagger.Secret,
	// Pip package to install within :arg ansible-dir:
	// +optional
	// +default=".[test]"
	pipPackage string,
	// Path to the Ansible directory, relative to :arg source:.
	// +optional
	// +default="ansible"
	ansibleDir string,
	// Project source directory
	// +optional
	// +ignore=["*cache*",".coverage",".env",".git*",".terraform",".venv","build","dist","node_modules","*.log"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Ansible {
	return &Ansible{
		AwsDefaultRegion:   awsDefaultRegion,
		AwsAccessKeyId:     awsAccessKeyId,
		AwsSecretAccessKey: awsSecretAccessKey,
		AwsSessionToken:    awsSessionToken,
		PipPackage:         pipPackage,
		AnsibleDir:         fmt.Sprintf("%s/%s", mountPoint, ansibleDir),
		Source:             source,
	}
}

type Ansible struct {
	AwsDefaultRegion   string
	AwsAccessKeyId     *dagger.Secret
	AwsSecretAccessKey *dagger.Secret
	AwsSessionToken    *dagger.Secret
	PipPackage         string
	AnsibleDir         string
	Source             *dagger.Directory
}

// Returns a container that echoes whatever string argument is provided
func (m *Ansible) container() *dagger.Container {
	awsDirPath := "/usr/local/aws-cli"

	return dag.Python().Venv().
		// Make the AWS CLI available within context
		WithDirectory(awsDirPath, dag.Container().From("docker.io/amazon/aws-cli:latest").Directory(awsDirPath)).
		WithExec([]string{"ln", "-s", fmt.Sprintf("%s/v2/current/bin/aws", awsDirPath), "/usr/local/bin/aws"}).
		WithEnvVariable("AWS_DEFAULT_REGION", m.AwsDefaultRegion).
		WithSecretVariable("AWS_ACCESS_KEY_ID", m.AwsAccessKeyId).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", m.AwsSecretAccessKey).
		WithSecretVariable("AWS_SESSION_TOKEN", m.AwsSessionToken).
		// Set up Ansible
		WithWorkdir(m.AnsibleDir).
		WithExec([]string{"pip", "install", "--root-user-action=ignore", m.PipPackage})
}

// Runs ansible-lint
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
