// A generated module for Compliance functions
//
// This module runs Anchore's Syft, Grype, etc. modules against the project
// source, generating SBOMs and licence data from dependencies.

package main

import (
	"context"
	"dagger/compliance/internal/dagger"
	"fmt"
)

var mountPoint = "/mnt"
var sbomPath = "/sbom.json"

// New - Default options for the Compliance Dagger module.
func New(
	// Version of Grype to use.
	// +optional
	// +default="0.116.0"
	grypeVersion string,
	// Version of Syft to use.
	// +optional
	// +default="1.49.0"
	syftVersion string,
	// Repository root dir.
	// +optional
	// +ignore=["*","!*/pyproject.toml","!/*.tf","!.github/workflows/*","!dagger/*"]
	// +defaultPath="/"
	source *dagger.Directory,
) *Compliance {
	return &Compliance{
		GrypeVersion: grypeVersion,
		SyftVersion:  syftVersion,
		Source:       source,
	}
}

// Compliance - Dagger module providing Anchore (syft/grype/grant) functionality
type Compliance struct {
	GrypeVersion string
	SyftVersion  string
	Source       *dagger.Directory
}

// Runs Syft inside dagger to generate a software bill of materials (SBOM)
func (m *Compliance) sbomFile() *dagger.File {
	syftCacheDir := "%s/.cache/syft"
	syftImage := fmt.Sprintf("docker.io/anchore/syft:v%s", m.SyftVersion)

	return dag.Container().
		From(syftImage).
		WithMountedDirectory(mountPoint, m.Source).
		WithMountedCache(syftCacheDir, dag.CacheVolume(syftImage)).
		WithWorkdir(mountPoint).
		WithEnvVariable("SYFT_CACHE_DIR", syftCacheDir).
		WithEnvVariable("SYFT_OUTPUT", fmt.Sprintf("spdx-json=%s", sbomPath)).
		WithExec([]string{"/syft", "scan", "."}).
		File(sbomPath)
}

// TODO: implement
// func (m *Compliance) Grype(ctx context.Context) (string, error) {}

// Sbom - Returns the contents of the Syft (SPDX) SBOM (JSON)
func (m *Compliance) Sbom(ctx context.Context) (string, error) {
	sbomPath := "/sbom.json"

	return dag.Container().
		From("docker.io/imega/jq:latest").
		WithMountedFile(sbomPath, m.sbomFile()).
		Terminal().
		WithExec([]string{"jq", ".", sbomPath}).
		Stdout(ctx)
}
