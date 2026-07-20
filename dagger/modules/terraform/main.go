// A generated module for Terraform functions.
//
// This module wraps common Terraform calls (validate, plan, apply), and runs
// them inside Dagger.

package main

import (
	"context"
	"dagger/terraform/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var tmpDir = "/tmp"

func New(
	// AWS default region
	awsDefaultRegion string,
	// AWS Access Key ID
	awsAccessKeyId *dagger.Secret,
	// AWS Secret Access Key
	awsSecretAccessKey *dagger.Secret,
	// AWS Session Token
	// +optional
	awsSessionToken *dagger.Secret,
	// Version of Terraform to run
	// +optional
	// +default="1.15.8"
	tfVersion string,
	// Repository root dir.
	// +optional
	// +ignore=["*cache*",".coverage",".env",".git*",".terraform",".venv","build","dist","node_modules","*.log"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Terraform {
	return &Terraform{
		AwsDefaultRegion:   awsDefaultRegion,
		AwsAccessKeyId:     awsAccessKeyId,
		AwsSecretAccessKey: awsSecretAccessKey,
		AwsSessionToken:    awsSessionToken,
		TerraformVersion:   tfVersion,
		Source:             source,
		Image:              "docker.io/hashicorp/terraform",
		Planfile:           fmt.Sprintf("%s/out.tfplan", tmpDir),
	}
}

type Terraform struct {
	AwsDefaultRegion   string
	AwsAccessKeyId     *dagger.Secret
	AwsSecretAccessKey *dagger.Secret
	AwsSessionToken    *dagger.Secret
	TerraformVersion   string
	Source             *dagger.Directory
	Image              string
	Planfile           string
}

// Returns a container with in initialized Terraform directory
func (m *Terraform) container() *dagger.Container {
	return dag.Container().
		From(fmt.Sprintf("%s:%s", m.Image, m.TerraformVersion)).
		WithMountedDirectory(mountPoint, m.Source)
}

// Returns a container with in initialized Terraform directory
func (m *Terraform) init(chdir string) *dagger.Container {
	return m.container().
		WithMountedCache(
			fmt.Sprintf("%s/%s/.terraform", mountPoint, chdir),
			dag.CacheVolume(fmt.Sprintf("%s-%s", mountPoint, chdir)),
		).
		WithMountedCache("/usr/bin", dag.CacheVolume("usr-bin")).
		WithExec([]string{"apk", "add", "pnpm", "libc6-compat"}).
		WithWorkdir(mountPoint).
		WithEnvVariable("AWS_DEFAULT_REGION", m.AwsDefaultRegion).
		WithSecretVariable("AWS_ACCESS_KEY_ID", m.AwsAccessKeyId).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", m.AwsSecretAccessKey).
		WithSecretVariable("AWS_SESSION_TOKEN", m.AwsSessionToken).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "init"})
}

// Returns a container a Terraform planfile at /tmp/out.tfplan.
func (m *Terraform) plan(chdir string, varFile string) *dagger.Container {
	extraArgs := ""

	if varFile != "" {
		extraArgs = fmt.Sprintf("-var-file=%s", varFile)
	}

	return m.init(chdir).
		WithMountedCache(tmpDir, dag.CacheVolume(chdir)).
		WithExec([]string{
			"terraform",
			fmt.Sprintf("-chdir=%s", chdir),
			"plan",
			extraArgs,
			fmt.Sprintf("-out=%s", m.Planfile),
		})
}

// Returns the output of 'terraform -chdir={} fmt -recursive -check'
// +check
func (m *Terraform) FmtRecursive(
	ctx context.Context,
	// Directory to run Terraform in. Passed as '-chdir={}'.
	// +optional
	// +default="."
	chdir string,
) (string, error) {
	stdout, err := m.init(chdir).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "fmt", "-check", "-recursive"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	} else {
		return stdout, nil
	}
}

// Returns the output of 'terraform plan'
func (m *Terraform) Validate(
	ctx context.Context,
	// Directory to run Terraform in. Passed as '-chdir={}'.
	chdir string,
) (string, error) {
	stdout, err := m.init(chdir).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "validate"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	} else {
		return stdout, nil
	}
}

// Returns the output of 'terraform plan'
func (m *Terraform) Plan(
	ctx context.Context,
	// Directory to run Terraform in. Passed as '-chdir={}'.
	chdir string,
	// Optional --var-file to pass. Must be relative to --chdir.
	// +default=""
	varFile string,
) (string, error) {
	stdout, err := m.plan(chdir, varFile).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "show", m.Planfile}).
		Stdout(ctx)

	if err != nil {
		return "", err
	} else {
		return stdout, nil
	}
}

// Returns the output of 'terraform plan'
func (m *Terraform) Apply(
	ctx context.Context,
	// Directory to run Terraform in. Passed as '-chdir={}'.
	chdir string,
	// Optional --var-file to pass
	// +default=""
	varFile string,
) (string, error) {
	stdout, err := m.plan(chdir, varFile).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "apply", "-auto-approve", m.Planfile}).
		Stdout(ctx)

	if err != nil {
		return "", fmt.Errorf("Error: %s", err)
	} else {
		return stdout, nil
	}
}
