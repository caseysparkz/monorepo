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

// New - Default options for the Terraform Dagger module.
func New(
	// AWS default region
	awsDefaultRegion string,
	// AWS Access Key ID
	awsAccessKeyID *dagger.Secret,
	// AWS Secret Access Key
	awsSecretAccessKey *dagger.Secret,
	// AWS Session Token
	// +optional
	awsSessionToken *dagger.Secret,
	// Version of Terraform to run
	// +optional
	// +default="1.15.8"
	terraformVersion string,
	// Repository root dir.
	// +optional
	// +ignore=["*","!terraform/"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Terraform {
	return &Terraform{
		AwsDefaultRegion:   awsDefaultRegion,
		AwsAccessKeyID:     awsAccessKeyID,
		AwsSecretAccessKey: awsSecretAccessKey,
		AwsSessionToken:    awsSessionToken,
		Version:            terraformVersion,
		Source:             source,
		Planfile:           fmt.Sprintf("%s/out.tfplan", tmpDir),
	}
}

// Terraform - the Terraform Dagger module.
type Terraform struct {
	AwsDefaultRegion   string
	AwsAccessKeyID     *dagger.Secret
	AwsSecretAccessKey *dagger.Secret
	AwsSessionToken    *dagger.Secret
	Version            string
	Source             *dagger.Directory
	Image              string
	Planfile           string
}

// Returns a container with an initialized Terraform directory.
func (m *Terraform) container() *dagger.Container {
	return dag.Container().
		From(fmt.Sprintf("docker.io/hashicorp/terraform:%s", m.Version)).
		WithMountedDirectory(mountPoint, m.Source)
}

// Returns a container with an initialized Terraform directory.
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
		WithSecretVariable("AWS_ACCESS_KEY_ID", m.AwsAccessKeyID).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", m.AwsSecretAccessKey).
		WithSecretVariable("AWS_SESSION_TOKEN", m.AwsSessionToken).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "init"})
}

// Returns a container with an initialized Terraform directory (no backend).
func (m *Terraform) initBackendFalse(chdir string) *dagger.Container {
	return m.container().
		WithMountedCache(
			fmt.Sprintf("%s/%s/.terraform", mountPoint, chdir),
			dag.CacheVolume(fmt.Sprintf("%s-%s", mountPoint, chdir)),
		).
		WithMountedCache("/usr/bin", dag.CacheVolume("usr-bin")).
		WithExec([]string{"apk", "add", "pnpm", "libc6-compat"}).
		WithWorkdir(mountPoint).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "init", "-backend=false"})
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

// Lint - Returns the output of 'terraform -chdir={:arg chdir:} fmt -recursive -check'.
// +check
func (m *Terraform) Lint(
	ctx context.Context,
	// Directory to run Terraform in. Passed as '-chdir={}'.
	// +optional
	// +default="."
	chdir string,
) (string, error) {
	_, err := m.initBackendFalse(chdir).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "fmt", "-check", "-recursive"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return "Files already formatted.", nil
}

// Validate - Returns the output of 'terraform -chdir={:arg chdir:} validate'.
func (m *Terraform) Validate(
	ctx context.Context,
	// Directory to run Terraform in. Passed as '-chdir={}'.
	chdir string,
) (string, error) {
	stdout, err := m.initBackendFalse(chdir).
		WithExec([]string{"terraform", fmt.Sprintf("-chdir=%s", chdir), "validate"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return stdout, nil
}

// Plan - Returns the output of 'terraform plan'.
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
	}

	return stdout, nil
}

// Apply - Returns the output of 'terraform apply'.
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
		return "", fmt.Errorf("error: %s", err)
	}

	return stdout, nil
}
